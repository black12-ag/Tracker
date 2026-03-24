import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class ProductionQuantityField extends StatelessWidget {
  const ProductionQuantityField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Quantity produced',
      hintText: '0',
      keyboardType: TextInputType.number,
      prefixIcon: Icons.format_list_numbered,
    );
  }
}
