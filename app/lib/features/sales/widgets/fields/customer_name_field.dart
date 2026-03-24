import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class CustomerNameField extends StatelessWidget {
  const CustomerNameField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Customer name',
      hintText: 'Shop or customer name',
      prefixIcon: Icons.person_outline,
    );
  }
}
