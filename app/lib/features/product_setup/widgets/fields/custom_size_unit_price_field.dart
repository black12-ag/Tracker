import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class CustomSizeUnitPriceField extends StatelessWidget {
  const CustomSizeUnitPriceField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Unit price',
      hintText: 'Add later if you want',
      prefixIcon: Icons.payments_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
    );
  }
}
