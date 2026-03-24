import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/buttons/password_visibility_toggle_button.dart';

class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: 'Password',
      hintText: 'Enter password',
      obscureText: !_isVisible,
      prefixIcon: Icons.lock_outline,
      suffixIcon: PasswordVisibilityToggleButton(
        isVisible: _isVisible,
        onPressed: () {
          setState(() => _isVisible = !_isVisible);
        },
      ),
      autofillHints: const [AutofillHints.password],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
    );
  }
}
