import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class CustomSizeLitersField extends StatelessWidget {
  const CustomSizeLitersField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Liters',
      hintText: '3.0',
      prefixIcon: Icons.water_drop_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
    );
  }
}
