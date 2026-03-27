import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

Future<Map<String, dynamic>?> showAddAccountDialog({
  required BuildContext context,
  required AppProfile profile,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AddAccountDialog(profile: profile),
  );
}

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
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
      final account = await ref.read(trackerRepositoryProvider).createAccount(
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
      Navigator.of(context).pop(account);
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
              hintText: 'Write name',
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
                if (value == null) {
                  return;
                }
                setState(() => _type = value);
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
