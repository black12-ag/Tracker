import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class ExpenseNoteField extends StatelessWidget {
  const ExpenseNoteField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Expense note',
      hintText: 'Optional detail',
      prefixIcon: Icons.notes_outlined,
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }
}
