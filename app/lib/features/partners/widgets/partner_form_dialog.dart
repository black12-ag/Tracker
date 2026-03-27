import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class PartnerFormDialog extends ConsumerStatefulWidget {
  const PartnerFormDialog({
    required this.createdBy,
    super.key,
    this.defaultType = 'customer',
  });

  final String createdBy;
  final String defaultType;

  @override
  ConsumerState<PartnerFormDialog> createState() => _PartnerFormDialogState();
}

class _PartnerFormDialogState extends ConsumerState<PartnerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  late String _partnerType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _noteController = TextEditingController();
    _partnerType = widget.defaultType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner name is required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final partner = await ref.read(trackerRepositoryProvider).createPartner(
            createdBy: widget.createdBy,
            name: _nameController.text,
            phone: _phoneController.text,
            partnerType: _partnerType,
            note: _noteController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(partner);
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
      title: const Text('Add Partner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hintText: 'Partner name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phoneController,
              label: 'Phone number',
              hintText: '0912345678',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _partnerType,
              decoration: const InputDecoration(
                labelText: 'Partner type',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                DropdownMenuItem(value: 'walk_in', child: Text('Walk in')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _partnerType = value);
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _noteController,
              label: 'Note',
              hintText: 'Optional',
              prefixIcon: Icons.notes_rounded,
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
          width: 110,
          child: PrimaryButton(
            label: 'Add',
            isBusy: _isSaving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
