import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class CustomSizeLabelField extends StatelessWidget {
  const CustomSizeLabelField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Size label',
      hintText: '3L',
      prefixIcon: Icons.sell_outlined,
      textInputAction: TextInputAction.next,
    );
  }
}
