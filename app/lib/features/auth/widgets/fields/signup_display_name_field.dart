import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SignupDisplayNameField extends StatelessWidget {
  const SignupDisplayNameField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Full name',
      hintText: 'Enter your name',
      prefixIcon: Icons.person_outline,
      textInputAction: TextInputAction.next,
    );
  }
}
