import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/core/models/app_profile.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/core/ui/buttons/primary_button.dart';
import 'package:tracker/core/ui/cards/app_surface_card.dart';
import 'package:tracker/core/ui/fields/app_text_field.dart';
import 'package:tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:tracker/core/utils/app_errors.dart';
import 'package:tracker/core/utils/formatters.dart';

class InventoryAdjustmentPage extends ConsumerStatefulWidget {
  const InventoryAdjustmentPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<InventoryAdjustmentPage> createState() =>
      _InventoryAdjustmentPageState();
}

class _InventoryAdjustmentPageState
    extends ConsumerState<InventoryAdjustmentPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _adjustments = const [];
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trackerRepositoryProvider);
      final adjustments = await repo.listInventoryAdjustments();
      final items = await repo.listInventoryItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _adjustments = adjustments;
        _items = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.humanize(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAdjustment() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _AdjustmentDialog(
        profile: widget.profile,
        items: _items,
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isOwner) {
      return ReferencePageScaffold(
        title: 'Inventory Adjustment',
        onMenuPressed: widget.onMenuPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This section is for the owner only.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return ReferencePageScaffold(
      title: 'Inventory Adjustment',
      onMenuPressed: widget.onMenuPressed,
      floatingActionButton: FloatingActionButton(
        onPressed: _addAdjustment,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: _isLoading
          ? const ReferenceListPageSkeleton(showSearch: false, itemCount: 4)
          : _adjustments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: _EmptyState(
                    icon: Icons.tune_rounded,
                    title: 'No adjustments yet',
                    message:
                        'Record a stock correction to keep your inventory counts accurate.',
                  ),
                )
              : AppSurfaceCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: _adjustments.indexed.map((entry) {
                      final index = entry.$1;
                      final adjustment = entry.$2;
                      final item = adjustment['inventory_items'] is Map
                          ? Map<String, dynamic>.from(
                              adjustment['inventory_items'] as Map,
                            )
                          : const <String, dynamic>{};
                      final isPlus =
                          adjustment['movement_type'] == 'adjustment_plus';
                      final qty = adjustment['quantity'] ?? 0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String? ?? 'Item',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.charcoal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${isPlus ? 'Positive' : 'Negative'}  •  ${AppFormatters.date(DateTime.tryParse((adjustment['movement_date'] as String?) ?? '') ?? DateTime.now())}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.warmGray,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${isPlus ? '+' : '-'}$qty',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: isPlus
                                            ? AppColors.navy
                                            : AppColors.danger,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (index < _adjustments.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.line,
                              thickness: 0.8,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class _AdjustmentDialog extends ConsumerStatefulWidget {
  const _AdjustmentDialog({
    required this.profile,
    required this.items,
  });

  final AppProfile profile;
  final List<Map<String, dynamic>> items;

  @override
  ConsumerState<_AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends ConsumerState<_AdjustmentDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  String? _itemId;
  String _movementType = 'adjustment_plus';
  final DateTime _movementDate = DateTime.now();
  bool _isSaving = false;
  String? _itemError;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_itemId == null) {
      setState(() => _itemError = 'Select an item');
      return;
    }

    setState(() {
      _itemError = null;
      _isSaving = true;
    });
    try {
      await ref.read(trackerRepositoryProvider).addInventoryAdjustment(
            createdBy: widget.profile.id,
            itemId: _itemId!,
            movementType: _movementType,
            quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
            movementDate: _movementDate,
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
      ).showSnackBar(SnackBar(content: Text(AppErrors.humanize(error))));
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
      title: const Text('Inventory Adjustment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _itemId,
              decoration: InputDecoration(
                labelText: 'Item',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                errorText: _itemError,
              ),
              items: widget.items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'] as String,
                  child: Text(item['name'] as String? ?? 'Item'),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() {
                _itemId = value;
                _itemError = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _movementType,
              decoration: const InputDecoration(labelText: 'Adjustment type'),
              items: const [
                DropdownMenuItem(
                  value: 'adjustment_plus',
                  child: Text('Positive Adjustment'),
                ),
                DropdownMenuItem(
                  value: 'adjustment_minus',
                  child: Text('Negative Adjustment'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _movementType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _quantityController,
              label: 'Quantity',
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 26, color: AppColors.navy),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.warmGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
