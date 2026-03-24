import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class FinanceInitialPaidField extends StatelessWidget {
  const FinanceInitialPaidField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Initial payment',
      hintText: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.payments_outlined,
    );
  }
}
