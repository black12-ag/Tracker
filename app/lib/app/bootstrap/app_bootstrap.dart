import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/shell/app_shell.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_error_view.dart';
import 'package:liquid_soap_tracker/features/auth/page/login_page.dart';
import 'package:liquid_soap_tracker/features/splash/page/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateChangesProvider);

    // Listen for unexpected sign-out events (e.g. JWT expired, token revoked)
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          ref.read(localStoreServiceProvider).clearAllCachedData();
          ref.invalidate(currentProfileProvider);
        }
      });
    });

    final session = ref.watch(currentSessionProvider);

    if (session == null) {
      return const LoginPage();
    }

    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const SplashPage();
        }

        if (!profile.isActive) {
          return AppErrorView(
            title: 'Account inactive',
            message:
                'This account is not active right now. Ask the owner to reactivate it.',
            actionLabel: 'Sign Out',
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          );
        }

        return AppShell(profile: profile);
      },
      loading: SplashPage.new,
      error: (error, stackTrace) => AppErrorView(
        title: 'We could not load your account',
        message: error.toString(),
        actionLabel: 'Try Again',
        onPressed: () => ref.invalidate(currentProfileProvider),
      ),
    );
  }
}
