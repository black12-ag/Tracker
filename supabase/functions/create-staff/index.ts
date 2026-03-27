import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type CreateStaffRequest = {
  name?: string;
  phone?: string;
  password?: string;
};

function normalizePhone(value: string): string {
  const digits = value.replace(/\D/g, '');
  if (digits.startsWith('251') && digits.length === 12) {
    return digits;
  }

  if (digits.startsWith('0') && digits.length === 10) {
    return `251${digits.substring(1)}`;
  }

  return digits;
}

function phoneToSyntheticEmail(phone: string): string {
  return `staff-${phone}@tracker.local`;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader) {
      return Response.json(
        { error: 'Missing authorization header.' },
        { status: 401, headers: corsHeaders },
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return Response.json(
        { error: 'Missing required Supabase environment variables.' },
        { status: 500, headers: corsHeaders },
      );
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: authError,
    } = await authClient.auth.getUser();

    if (authError || !user) {
      return Response.json(
        { error: 'Invalid auth session.' },
        { status: 401, headers: corsHeaders },
      );
    }

    const { data: callerProfile, error: profileError } = await serviceClient
      .from('profiles')
      .select('id, role, is_active')
      .eq('id', user.id)
      .maybeSingle();

    if (profileError || callerProfile == null) {
      return Response.json(
        { error: 'Unable to load caller profile.' },
        { status: 403, headers: corsHeaders },
      );
    }

    if (callerProfile.role !== 'owner' || callerProfile.is_active != true) {
      return Response.json(
        { error: 'Owner access is required.' },
        { status: 403, headers: corsHeaders },
      );
    }

    const payload = (await request.json()) as CreateStaffRequest;
    const name = payload.name?.trim() ?? '';
    const password = payload.password?.trim() ?? '';
    const phone = payload.phone?.trim() ?? '';
    const normalizedPhone = normalizePhone(phone);

    if (name.length === 0 || normalizedPhone.length === 0 || password.length === 0) {
      return Response.json(
        { error: 'Name, phone, and password are required.' },
        { status: 400, headers: corsHeaders },
      );
    }

    if (password.length < 8) {
      return Response.json(
        { error: 'Password must be at least 8 characters.' },
        { status: 400, headers: corsHeaders },
      );
    }

    const { data: existingProfile } = await serviceClient
      .from('profiles')
      .select('id')
      .eq('phone', normalizedPhone)
      .maybeSingle();

    if (existingProfile != null) {
      return Response.json(
        { error: 'A staff member with this phone number already exists.' },
        { status: 409, headers: corsHeaders },
      );
    }

    const syntheticEmail = phoneToSyntheticEmail(normalizedPhone);

    const { data: createdUser, error: createUserError } =
      await serviceClient.auth.admin.createUser({
        email: syntheticEmail,
        password,
        email_confirm: true,
        user_metadata: {
          display_name: name,
          phone: normalizedPhone,
          created_by_owner: user.id,
        },
      });

    if (createUserError || !createdUser.user) {
      return Response.json(
        { error: createUserError?.message ?? 'Unable to create staff user.' },
        { status: 400, headers: corsHeaders },
      );
    }

    const { error: updateProfileError } = await serviceClient
      .from('profiles')
      .update({
        role: 'staff',
        is_active: true,
        display_name: name,
        phone: normalizedPhone,
        created_by_owner: user.id,
      })
      .eq('id', createdUser.user.id);

    if (updateProfileError) {
      await serviceClient.auth.admin.deleteUser(createdUser.user.id);
      return Response.json(
        { error: updateProfileError.message },
        { status: 500, headers: corsHeaders },
      );
    }

    return Response.json(
      {
        id: createdUser.user.id,
        email: syntheticEmail,
        display_name: name,
        phone: normalizedPhone,
        role: 'staff',
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    return Response.json(
      { error: error instanceof Error ? error.message : 'Unexpected error.' },
      { status: 500, headers: corsHeaders },
    );
  }
});
