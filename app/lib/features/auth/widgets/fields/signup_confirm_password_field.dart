import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/buttons/password_visibility_toggle_button.dart';

class SignupConfirmPasswordField extends StatefulWidget {
  const SignupConfirmPasswordField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  State<SignupConfirmPasswordField> createState() =>
      _SignupConfirmPasswordFieldState();
}

class _SignupConfirmPasswordFieldState
    extends State<SignupConfirmPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: 'Confirm password',
      hintText: 'Re-enter password',
      obscureText: !_isVisible,
      prefixIcon: Icons.verified_user_outlined,
      suffixIcon: PasswordVisibilityToggleButton(
        isVisible: _isVisible,
        onPressed: () {
          setState(() => _isVisible = !_isVisible);
        },
      ),
      autofillHints: const [AutofillHints.newPassword],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
    );
  }
}
