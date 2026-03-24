import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/expense_amount_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/expense_category_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/expense_note_field.dart';

class ExpenseFormSection extends StatelessWidget {
  const ExpenseFormSection({
    required this.categoryController,
    required this.amountController,
    required this.noteController,
    required this.expenseDate,
    super.key,
  });

  final TextEditingController categoryController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final DateTime expenseDate;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Add expense',
            subtitle: 'Write any business cost you want counted.',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(AppFormatters.date(expenseDate)),
          ),
          const SizedBox(height: 12),
          ExpenseCategoryField(controller: categoryController),
          const SizedBox(height: 12),
          ExpenseAmountField(controller: amountController),
          const SizedBox(height: 12),
          ExpenseNoteField(controller: noteController),
        ],
      ),
    );
  }
}
