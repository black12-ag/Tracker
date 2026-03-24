import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SalesNotesField extends StatelessWidget {
  const SalesNotesField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Notes',
      hintText: 'Optional notes',
      maxLines: 3,
      prefixIcon: Icons.notes_outlined,
    );
  }
}
