import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class ProductNameField extends StatelessWidget {
  const ProductNameField({
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
      label: 'Product name',
      hintText: 'Liquid Soap',
      readOnly: readOnly,
      prefixIcon: Icons.local_drink_outlined,
    );
  }
}
