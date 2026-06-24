import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/app/shell/app_shell.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/core/models/app_profile.dart';
import 'package:tracker/core/ui/states/app_error_view.dart';
import 'package:tracker/features/auth/page/login_page.dart';
import 'package:tracker/features/onboarding/page/welcome_onboarding_page.dart';
import 'package:tracker/features/splash/page/splash_page.dart';
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

        return _OnboardingGate(profile: profile);
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

/// Shows the one-time welcome screen to a freshly registered owner, then
/// hands off to the main app. Staff and returning owners go straight through.
class _OnboardingGate extends ConsumerStatefulWidget {
  const _OnboardingGate({required this.profile});

  final AppProfile profile;

  @override
  ConsumerState<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<_OnboardingGate> {
  bool? _showWelcome;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // Only owners get the welcome tour; staff are onboarded by their owner.
    if (!widget.profile.isOwner) {
      setState(() => _showWelcome = false);
      return;
    }
    final seen = await ref
        .read(localStoreServiceProvider)
        .hasSeenOnboarding(widget.profile.id);
    if (mounted) {
      setState(() => _showWelcome = !seen);
    }
  }

  Future<void> _complete() async {
    await ref
        .read(localStoreServiceProvider)
        .markOnboardingSeen(widget.profile.id);
    if (mounted) {
      setState(() => _showWelcome = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome == null) {
      return const SplashPage();
    }
    if (_showWelcome!) {
      return WelcomeOnboardingPage(
        profile: widget.profile,
        onContinue: _complete,
      );
    }
    return AppShell(profile: widget.profile);
  }
}
