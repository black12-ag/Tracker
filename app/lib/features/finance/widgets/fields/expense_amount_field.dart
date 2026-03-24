import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class ExpenseAmountField extends StatelessWidget {
  const ExpenseAmountField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Expense amount',
      hintText: 'Enter expense amount',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.payments_outlined,
      textInputAction: TextInputAction.next,
    );
  }
}
