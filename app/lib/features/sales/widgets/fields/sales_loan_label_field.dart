import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SalesLoanLabelField extends StatelessWidget {
  const SalesLoanLabelField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Balance note',
      hintText: 'Optional note for money left',
      prefixIcon: Icons.badge_outlined,
    );
  }
}
