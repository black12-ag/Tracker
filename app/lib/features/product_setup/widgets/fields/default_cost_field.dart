import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class DefaultCostField extends StatelessWidget {
  const DefaultCostField({
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
      label: 'Default cost per liter',
      hintText: '0.00',
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.payments_outlined,
    );
  }
}
