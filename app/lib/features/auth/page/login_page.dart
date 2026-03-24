import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/ghost_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/features/auth/controller/auth_controller.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/buttons/login_submit_button.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/fields/login_email_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/fields/login_password_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/fields/signup_confirm_password_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/fields/signup_display_name_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/sections/auth_contact_footer.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _isSignup = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(Object error) {
    if (OfflineErrorDetector.isLikelyOffline(error)) {
      return 'No internet connection. Turn on Wi-Fi or mobile data and try again.';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Wrong login details or password. Please try again.';
    }
    if (message.contains('user already registered')) {
      return 'This email already has an account. Login instead.';
    }
    if (message.contains('password')) {
      return 'Please check your password and try again.';
    }

    return 'We could not complete that right now. Please try again.';
  }

  Future<void> _submit() async {
    final displayName = _displayNameController.text.trim();
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login details and password are required.'),
        ),
      );
      return;
    }

    if (_isSignup) {
      if (displayName.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Your name is required.')));
        return;
      }

      if (password.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 8 characters long.'),
          ),
        );
        return;
      }

      if (password != _confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      if (!identifier.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use an email address when creating a new account.'),
          ),
        );
        return;
      }
    }

    ref.read(authSubmitLoadingProvider.notifier).state = true;
    try {
      if (_isSignup) {
        await ref
            .read(authRepositoryProvider)
            .signUp(
              displayName: displayName,
              email: identifier,
              password: password,
            );
      }

      await ref
          .read(authRepositoryProvider)
          .signIn(identifier: identifier, password: password);
      ref.invalidate(currentProfileProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
    } finally {
      ref.read(authSubmitLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authSubmitLoadingProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const SizedBox(height: 28),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppIdentity.appName.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 3,
                      color: AppColors.oliveDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to track production, sales, stock, and money.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.warmGray),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              AppSurfaceCard(
                padding: const EdgeInsets.all(22),
                child: AutofillGroup(
                  child: Column(
                    children: [
                      if (_isSignup) ...[
                        SignupDisplayNameField(
                          controller: _displayNameController,
                        ),
                        const SizedBox(height: 16),
                      ],
                      LoginEmailField(
                        controller: _emailController,
                        label: _isSignup
                            ? 'Email address'
                            : 'Email or phone number',
                        hintText: _isSignup
                            ? 'name@company.com'
                            : 'name@company.com or 092 2380260',
                      ),
                      const SizedBox(height: 16),
                      LoginPasswordField(controller: _passwordController),
                      if (_isSignup) ...[
                        const SizedBox(height: 16),
                        SignupConfirmPasswordField(
                          controller: _confirmPasswordController,
                        ),
                      ],
                      const SizedBox(height: 24),
                      LoginSubmitButton(
                        onPressed: _submit,
                        isBusy: isBusy,
                        label: _isSignup
                            ? 'Create account'
                            : 'Login',
                        icon: _isSignup
                            ? Icons.person_add_alt_1_rounded
                            : Icons.arrow_forward,
                      ),
                      const SizedBox(height: 12),
                      GhostButton(
                        label: _isSignup
                            ? 'Back to login'
                            : 'Create new account',
                        onPressed: () {
                          setState(() => _isSignup = !_isSignup);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSignup
                    ? 'New accounts get shared access for product, production, and sales.'
                    : 'The owner can use the business phone number. Other users sign in with email.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const AuthContactFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
