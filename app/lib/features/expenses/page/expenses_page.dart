import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = const [];
  List<Map<String, dynamic>> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trackerRepositoryProvider);
      final expenses = await repo.listExpenses();
      final accounts = await repo.listAccountSummaries();
      if (!mounted) {
        return;
      }
      setState(() {
        _expenses = expenses;
        _accounts = accounts;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addExpense() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _AddExpenseDialog(
        profile: widget.profile,
        accounts: _accounts,
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Expenses',
      onMenuPressed: widget.onMenuPressed,
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: _isLoading
          ? const ReferenceListPageSkeleton(
              showSearch: false,
              itemCount: 5,
            )
          : _expenses.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(
                    'No expenses found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : AppSurfaceCard(
                  child: Column(
                    children: _expenses.map((expense) {
                      final account = expense['accounts'] is Map
                          ? Map<String, dynamic>.from(expense['accounts'] as Map)
                          : const <String, dynamic>{};
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          expense['category'] as String? ?? 'Expense',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${AppFormatters.date(DateTime.tryParse((expense['expense_date'] as String?) ?? '') ?? DateTime.now())} • ${account['account_name'] ?? 'No account'}',
                        ),
                        trailing: Text(
                          AppFormatters.currency(
                            (expense['amount'] as num?)?.toDouble() ?? 0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog({
    required this.profile,
    required this.accounts,
  });

  final AppProfile profile;
  final List<Map<String, dynamic>> accounts;

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final DateTime _expenseDate = DateTime.now();
  String? _accountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category is required.')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(trackerRepositoryProvider).createExpense(
            createdBy: widget.profile.id,
            category: _categoryController.text,
            amount: amount,
            expenseDate: _expenseDate,
            accountId: _accountId,
            note: _noteController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _categoryController,
              label: 'Category',
              hintText: 'Expense category',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: widget.accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account['account_id'] as String,
                  child: Text(account['account_name'] as String? ?? 'Account'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _accountId = value),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Note',
              hintText: 'Optional',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 120,
          child: PrimaryButton(
            label: 'Save',
            isBusy: _isSaving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
