import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class LoginEmailField extends StatelessWidget {
  const LoginEmailField({
    required this.controller,
    this.label = 'Email or phone number',
    this.hintText = 'name@company.com or 092 2380260',
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.mail_outline,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
    );
  }
}
