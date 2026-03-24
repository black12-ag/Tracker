import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class ExpenseCategoryField extends StatelessWidget {
  const ExpenseCategoryField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Expense category',
      hintText: 'Packaging, transport, salary...',
      prefixIcon: Icons.category_outlined,
      textInputAction: TextInputAction.next,
    );
  }
}
