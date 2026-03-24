import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class CustomSizeLowStockField extends StatelessWidget {
  const CustomSizeLowStockField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Low stock alert',
      hintText: '0',
      prefixIcon: Icons.warning_amber_rounded,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
    );
  }
}
