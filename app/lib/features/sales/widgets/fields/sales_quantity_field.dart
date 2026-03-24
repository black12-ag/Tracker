import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SalesQuantityField extends StatelessWidget {
  const SalesQuantityField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Quantity sold',
      hintText: '0',
      keyboardType: TextInputType.number,
      prefixIcon: Icons.shopping_bag_outlined,
    );
  }
}
