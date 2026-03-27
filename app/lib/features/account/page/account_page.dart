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
import 'package:liquid_soap_tracker/features/account/widgets/add_account_dialog.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = const [];

  @override
  void initState() {
    super.initState();
    if (widget.profile.isOwner) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await ref.read(trackerRepositoryProvider).listAccountSummaries();
      if (!mounted) {
        return;
      }
      setState(() => _accounts = accounts);
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

  Future<void> _showActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('Add account'),
                onTap: () => Navigator.of(context).pop('add'),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Transfer to other bank'),
                onTap: () => Navigator.of(context).pop('transfer'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    final saved = action == 'add'
        ? await _showAddAccountDialog()
        : await _showTransferDialog();

    if (saved == true) {
      await _load();
    }
  }

  Future<bool?> _showAddAccountDialog() {
    return showAddAccountDialog(
      context: context,
      profile: widget.profile,
    ).then((value) => value == null ? null : true);
  }

  Future<bool?> _showTransferDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => _TransferDialog(
        profile: widget.profile,
        accounts: _accounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isOwner) {
      return ReferencePageScaffold(
        title: 'Account',
        onMenuPressed: widget.onMenuPressed,
        showBottomNavigation: false,
        child: AppSurfaceCard(
          color: AppColors.mintSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profile.displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 8),
              Text(widget.profile.email),
              if (widget.profile.phone != null) ...[
                const SizedBox(height: 4),
                Text(widget.profile.phone!),
              ],
              const SizedBox(height: 14),
              Text(
                'Account balances and bank actions are hidden for staff.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filteredAccounts = _accounts.where((account) {
      if (query.isEmpty) {
        return true;
      }
      final name = (account['account_name'] as String? ?? '').toLowerCase();
      final bank = (account['bank_name'] as String? ?? '').toLowerCase();
      return name.contains(query) || bank.contains(query);
    }).toList();
    final totalBalance = filteredAccounts.fold<double>(
      0,
      (sum, account) =>
          sum + ((account['current_balance'] as num?)?.toDouble() ?? 0),
    );

    return ReferencePageScaffold(
      title: 'Account',
      onMenuPressed: widget.onMenuPressed,
      showBottomNavigation: false,
      floatingActionButton: FloatingActionButton(
        onPressed: _showActions,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.menu_rounded),
      ),
      child: Column(
        children: [
          AppSurfaceCard(
            color: AppColors.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppFormatters.currency(totalBalance),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _searchController,
            label: 'Search accounts',
            hintText: 'Search accounts',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(
              showTopCard: true,
              itemCount: 4,
            )
          else if (filteredAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Text(
                'No accounts found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            AppSurfaceCard(
              child: Column(
                children: filteredAccounts.map((account) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      account['account_name'] as String? ?? 'Account',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      [
                        account['bank_name'] as String? ?? '',
                        account['account_type'] as String? ?? '',
                      ].where((value) => value.isNotEmpty).join(' • '),
                    ),
                    trailing: Text(
                      AppFormatters.currency(
                        (account['current_balance'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddAccountDialog extends ConsumerStatefulWidget {
  const _AddAccountDialog({required this.profile});

  final AppProfile profile;

  @override
  ConsumerState<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<_AddAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late final TextEditingController _bankController;
  late final TextEditingController _balanceController;
  String _type = 'cash';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _bankController = TextEditingController();
    _balanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _bankController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account name is required.')),
      );
      return;
    }
    final openingBalance = double.tryParse(_balanceController.text.trim()) ?? 0;
    if (openingBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance cannot be negative.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(trackerRepositoryProvider).createAccount(
            createdBy: widget.profile.id,
            accountName: _nameController.text,
            accountNumber: _numberController.text,
            bankName: _bankController.text,
            accountType: _type,
            openingBalance: openingBalance,
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
      title: const Text('Add New Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Account holder name',
              hintText: 'Enter account name',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _numberController,
              label: 'Account number',
              hintText: 'Enter account number',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bankController,
              label: 'Bank',
              hintText: 'Write bank name',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _balanceController,
              label: 'Balance',
              hintText: 'Enter balance',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _TransferDialog extends ConsumerStatefulWidget {
  const _TransferDialog({
    required this.profile,
    required this.accounts,
  });

  final AppProfile profile;
  final List<Map<String, dynamic>> accounts;

  @override
  ConsumerState<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<_TransferDialog> {
  String? _fromAccountId;
  String? _toAccountId;
  final DateTime _transferDate = DateTime.now();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose both accounts.')),
      );
      return;
    }
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different accounts.')),
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
      await ref.read(trackerRepositoryProvider).createTransfer(
            createdBy: widget.profile.id,
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            amount: amount,
            transferDate: _transferDate,
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
      title: const Text('Transfer to Other Bank'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fromAccountId,
              decoration: const InputDecoration(labelText: 'From account'),
              items: widget.accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account['account_id'] as String,
                  child: Text(account['account_name'] as String? ?? 'Account'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _fromAccountId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _toAccountId,
              decoration: const InputDecoration(labelText: 'To account'),
              items: widget.accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account['account_id'] as String,
                  child: Text(account['account_name'] as String? ?? 'Account'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _toAccountId = value),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Additional information',
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
