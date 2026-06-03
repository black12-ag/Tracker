import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
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
  bool _isSignUp = false;

  // Login controllers
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // Sign-up controllers
  late final TextEditingController _signupDisplayNameController;
  late final TextEditingController _signupBusinessNameController;
  late final TextEditingController _signupEmailController;
  late final TextEditingController _signupPasswordController;
  late final TextEditingController _signupConfirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _signupDisplayNameController = TextEditingController();
    _signupBusinessNameController = TextEditingController();
    _signupEmailController = TextEditingController();
    _signupPasswordController = TextEditingController();
    _signupConfirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupDisplayNameController.dispose();
    _signupBusinessNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  // Inline validation message shown inside the auth card. Null = no error.
  String? _formError;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _showError(String message) {
    setState(() => _formError = message);
  }

  void _clearError() {
    if (_formError != null) {
      setState(() => _formError = null);
    }
  }

  String _friendlyAuthError(Object error) {
    if (OfflineErrorDetector.isLikelyOffline(error)) {
      return 'No internet connection. Turn on Wi-Fi or mobile data and try again.';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Wrong login details or password. Please try again.';
    }
    if (message.contains('password')) {
      return 'Please check your password and try again.';
    }

    return 'We could not complete that right now. Please try again.';
  }

  Future<void> _submit() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Enter your email or phone number and password.');
      return;
    }
    _clearError();

    ref.read(authSubmitLoadingProvider.notifier).state = true;
    try {
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

  Future<void> _signUp() async {
    final displayName = _signupDisplayNameController.text.trim();
    final businessName = _signupBusinessNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text.trim();
    final confirmPassword = _signupConfirmPasswordController.text.trim();

    if (displayName.isEmpty ||
        businessName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields to create your account.');
      return;
    }

    if (!_emailPattern.hasMatch(email)) {
      _showError('Enter a valid email address, e.g. name@company.com.');
      return;
    }

    if (password.length < 8) {
      _showError('Use a password with at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('The two passwords do not match.');
      return;
    }
    _clearError();

    ref.read(authSubmitLoadingProvider.notifier).state = true;
    try {
      await ref.read(authRepositoryProvider).signUp(
            displayName: displayName,
            email: email,
            password: password,
            businessName: businessName,
          );
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

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email on your account and we will send you a '
                'link to set a new password.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller,
                label: 'Email',
                hintText: 'name@company.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Send link'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (email == null || email.isEmpty) {
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      _showError('Enter a valid email to receive a reset link.');
      return;
    }

    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email for a password reset link.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authSubmitLoadingProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                      color: AppColors.accentBlueDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSignUp
                        ? 'Set up your business account to get started.'
                        : 'Sign in to manage sales, purchased items, inventory, accounts, and reports.',
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
                child: Column(
                  children: [
                    // Tab toggle
                    Row(
                      children: [
                        _TabButton(
                          label: 'Login',
                          isSelected: !_isSignUp,
                          onTap: () => setState(() {
                            _isSignUp = false;
                            _formError = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _TabButton(
                          label: 'Sign Up',
                          isSelected: _isSignUp,
                          onTap: () => setState(() {
                            _isSignUp = true;
                            _formError = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_formError != null) ...[
                      _ErrorBanner(message: _formError!),
                      const SizedBox(height: 16),
                    ],
                    // Fields lock while a request is in flight to prevent
                    // double-submits and mid-flight edits.
                    AbsorbPointer(
                      absorbing: isBusy,
                      child: Opacity(
                        opacity: isBusy ? 0.6 : 1,
                        child: !_isSignUp
                            ? AutofillGroup(
                                child: Column(
                                  children: [
                                    LoginEmailField(
                                      controller: _emailController,
                                      label: 'Email or phone number',
                                      hintText:
                                          'name@company.com or 092 2380260',
                                    ),
                                    const SizedBox(height: 16),
                                    LoginPasswordField(
                                      controller: _passwordController,
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _forgotPassword,
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                          foregroundColor:
                                              AppColors.accentBlueDark,
                                        ),
                                        child: const Text('Forgot password?'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LoginSubmitButton(
                                      onPressed: _submit,
                                      isBusy: isBusy,
                                      label: 'Login',
                                      icon: Icons.arrow_forward,
                                    ),
                                  ],
                                ),
                              )
                            : AutofillGroup(
                                child: Column(
                                  children: [
                                    SignupDisplayNameField(
                                      controller: _signupDisplayNameController,
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _signupBusinessNameController,
                                      label: 'Business name',
                                      hintText:
                                          "The name customers see, e.g. Mary's Shop",
                                      prefixIcon: Icons.store_outlined,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 16),
                                    LoginEmailField(
                                      controller: _signupEmailController,
                                      label: 'Email',
                                      hintText: 'name@company.com',
                                    ),
                                    const SizedBox(height: 16),
                                    LoginPasswordField(
                                      controller: _signupPasswordController,
                                    ),
                                    const SizedBox(height: 16),
                                    SignupConfirmPasswordField(
                                      controller:
                                          _signupConfirmPasswordController,
                                    ),
                                    const SizedBox(height: 24),
                                    LoginSubmitButton(
                                      onPressed: _signUp,
                                      isBusy: isBusy,
                                      label: 'Create my business',
                                      icon: Icons.check,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp
                          ? 'Free to start. You become the owner of your own '
                              'workspace and can add staff later.'
                          : 'Owners sign in with email or phone. Staff sign in '
                              'with the phone and password their owner set.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warmGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AuthContactFooter(),
            ],
          ),
        ),
    );
  }
}


class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : AppColors.warmGray,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
