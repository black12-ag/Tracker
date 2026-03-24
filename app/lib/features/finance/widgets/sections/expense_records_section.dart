import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/finance/models/expense_entry.dart';

class ExpenseRecordsSection extends StatelessWidget {
  const ExpenseRecordsSection({required this.items, super.key});

  final List<ExpenseEntry> items;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Recent expenses',
            subtitle: 'Costs already counted in profit',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No expenses recorded yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.category),
                subtitle: Text(AppFormatters.date(item.expenseDate)),
                trailing: Text(
                  AppFormatters.currency(item.amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: DisplayCleaner.note(item.note) == null
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: false,
                        builder: (context) => SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 44,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).dividerColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Expense details',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 14),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Category'),
                                  subtitle: Text(item.category),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Amount'),
                                  subtitle: Text(
                                    AppFormatters.currency(item.amount),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Date'),
                                  subtitle: Text(
                                    AppFormatters.date(item.expenseDate),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Notes'),
                                  subtitle: Text(
                                    DisplayCleaner.note(item.note)!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
