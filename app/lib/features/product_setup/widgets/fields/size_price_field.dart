import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SizePriceField extends StatelessWidget {
  const SizePriceField({
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
      label: 'Unit price',
      hintText: 'Add later if you want',
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.sell_outlined,
    );
  }
}
