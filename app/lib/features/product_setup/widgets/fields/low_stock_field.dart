import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class LowStockField extends StatelessWidget {
  const LowStockField({
    required this.controller,
    required this.readOnly,
    super.key,
  });

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Low stock threshold',
      hintText: '0',
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.warning_amber_rounded,
    );
  }
}
