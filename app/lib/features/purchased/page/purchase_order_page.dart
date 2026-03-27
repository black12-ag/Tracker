import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/account/widgets/add_account_dialog.dart';
import 'package:liquid_soap_tracker/features/inventory/page/inventory_item_page.dart';
import 'package:liquid_soap_tracker/features/partners/widgets/partner_form_dialog.dart';

class PurchaseOrderPage extends ConsumerStatefulWidget {
  const PurchaseOrderPage({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends ConsumerState<PurchaseOrderPage> {
  final List<_PurchaseLineDraft> _lines = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _unitPriceController = TextEditingController();
  DateTime _orderDate = DateTime.now();
  DateTime _receiveDate = DateTime.now();
  int _step = 0;
  String? _selectedPartnerId;
  String? _selectedAccountId;
  String? _selectedItemId;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _partners = const [];
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _paidAmountController.addListener(_refreshDraft);
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _paidAmountController
      ..removeListener(_refreshDraft)
      ..dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _refreshDraft() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final tracker = ref.read(trackerRepositoryProvider);
      final partners = await tracker.listPartners();
      final items = await tracker.listInventoryItems();
      final accounts = widget.profile.isOwner
          ? await tracker.listAccountSummaries()
          : <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _partners = partners;
        _items = items;
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

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _addPartner() async {
    final partner = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PartnerFormDialog(
        createdBy: widget.profile.id,
        defaultType: 'supplier',
      ),
    );
    if (partner == null) {
      return;
    }

    await _load();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPartnerId = partner['id'] as String?;
    });
  }

  Future<void> _addInventoryItem() async {
    final item = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => InventoryItemPage(profile: widget.profile),
      ),
    );
    if (item == null) {
      return;
    }

    await _load();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedItemId = item['id'] as String?;
      final boughtPrice = (item['bought_price'] as num?)?.toDouble() ?? 0;
      _unitPriceController.text = boughtPrice <= 0
          ? ''
          : boughtPrice.toStringAsFixed(
              boughtPrice == boughtPrice.roundToDouble() ? 0 : 2,
            );
    });
  }

  Future<void> _addAccount() async {
    final account = await showAddAccountDialog(
      context: context,
      profile: widget.profile,
    );
    if (account == null) {
      return;
    }

    await _load();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAccountId = account['id'] as String?;
    });
  }

  void _goNext() {
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a supplier before going next.')),
      );
      return;
    }

    setState(() => _step = 1);
  }

  bool _addItemLine({bool showMessages = true}) {
    if (_selectedItemId == null) {
      if (showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an item first.')),
        );
      }
      return false;
    }

    final item = _items.firstWhere(
      (entry) => entry['id'] == _selectedItemId,
      orElse: () => const {},
    );
    if (item.isEmpty) {
      if (showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item could not be found.')),
        );
      }
      return false;
    }

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0) {
      if (showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity must be greater than 0.')),
        );
      }
      return false;
    }

    final fallbackPrice = (item['bought_price'] as num?)?.toDouble() ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ??
        fallbackPrice;
    if (unitPrice <= 0) {
      if (showMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a purchase price before adding this item.'),
          ),
        );
      }
      return false;
    }

    setState(() {
      _lines.add(
        _PurchaseLineDraft(
          itemId: _selectedItemId!,
          itemName: item['name'] as String? ?? 'Item',
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
      _selectedItemId = null;
      _quantityController.text = '1';
      _unitPriceController.clear();
    });
    return true;
  }

  Future<void> _save() async {
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a supplier.')),
      );
      return;
    }

    if (_lines.isEmpty && _selectedItemId != null) {
      _addItemLine(showMessages: false);
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one purchase item.')),
      );
      return;
    }

    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? 0;
    if (paidAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid amount cannot be negative.')),
      );
      return;
    }
    if (paidAmount > _draftTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot be more than the total.'),
        ),
      );
      return;
    }
    if (widget.profile.isOwner && paidAmount > 0 && _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an account for the payment.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(trackerRepositoryProvider).createPurchaseOrder(
            createdBy: widget.profile.id,
            partnerId: _selectedPartnerId,
            orderDate: _orderDate,
            receiveDate: _receiveDate,
            note: _noteController.text,
            paidAmount: widget.profile.isOwner ? paidAmount : 0,
            accountId: widget.profile.isOwner ? _selectedAccountId : null,
            items: _lines
                .map(
                  (line) => {
                    'item_id': line.itemId,
                    'quantity': line.quantity,
                    'unit_price': line.unitPrice,
                  },
                )
                .toList(),
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

  double get _draftTotal => _lines.fold<double>(
        0,
        (sum, line) => sum + (line.quantity * line.unitPrice),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase Order'),
        backgroundColor: AppColors.mintSoft,
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [ReferenceOrderPageSkeleton()],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_step == 0)
                  _PurchaseHeaderStep(
                    partners: _partners,
                    selectedPartnerId: _selectedPartnerId,
                    orderDate: _orderDate,
                    receiveDate: _receiveDate,
                    noteController: _noteController,
                    onPartnerChanged: (value) {
                      setState(() => _selectedPartnerId = value);
                    },
                    onAddPartner: _addPartner,
                    onOrderDatePressed: () => _pickDate(
                      initialDate: _orderDate,
                      onPicked: (value) => setState(() => _orderDate = value),
                    ),
                    onReceiveDatePressed: () => _pickDate(
                      initialDate: _receiveDate,
                      onPicked: (value) => setState(() => _receiveDate = value),
                    ),
                  )
                else
                  _PurchaseItemsStep(
                    partners: _partners,
                    items: _items,
                    lines: _lines,
                    isOwner: widget.profile.isOwner,
                    selectedItemId: _selectedItemId,
                    selectedAccountId: _selectedAccountId,
                    accounts: _accounts,
                    paidAmountController: _paidAmountController,
                    quantityController: _quantityController,
                    unitPriceController: _unitPriceController,
                    onAddPartner: _addPartner,
                    onAddInventoryItem: _addInventoryItem,
                    onAddAccount: _addAccount,
                    onItemChanged: (value) {
                      setState(() {
                        _selectedItemId = value;
                        final item = _items.firstWhere(
                          (entry) => entry['id'] == value,
                          orElse: () => const {},
                        );
                        final boughtPrice =
                            (item['bought_price'] as num?)?.toDouble() ?? 0;
                        _unitPriceController.text = boughtPrice <= 0
                            ? ''
                            : boughtPrice.toStringAsFixed(
                                boughtPrice == boughtPrice.roundToDouble()
                                    ? 0
                                    : 2,
                              );
                      });
                    },
                    onAccountChanged: (value) {
                      setState(() => _selectedAccountId = value);
                    },
                    onQuantityChanged: (_) => _refreshDraft(),
                    onUnitPriceChanged: (_) => _refreshDraft(),
                    onPaidAmountChanged: (_) => _refreshDraft(),
                    onRemoveLine: (line) {
                      setState(() => _lines.remove(line));
                    },
                    onAddLine: _addItemLine,
                    total: _draftTotal,
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _step == 0
                      ? () => Navigator.of(context).maybePop()
                      : () => setState(() => _step = 0),
                  child: Text(_step == 0 ? 'Cancel' : 'Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _step == 0 ? 'Next' : 'Save',
                  isBusy: _isSaving,
                  onPressed: _step == 0 ? _goNext : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseHeaderStep extends StatelessWidget {
  const _PurchaseHeaderStep({
    required this.partners,
    required this.selectedPartnerId,
    required this.orderDate,
    required this.receiveDate,
    required this.noteController,
    required this.onPartnerChanged,
    required this.onAddPartner,
    required this.onOrderDatePressed,
    required this.onReceiveDatePressed,
  });

  final List<Map<String, dynamic>> partners;
  final String? selectedPartnerId;
  final DateTime orderDate;
  final DateTime receiveDate;
  final TextEditingController noteController;
  final ValueChanged<String?> onPartnerChanged;
  final VoidCallback onAddPartner;
  final VoidCallback onOrderDatePressed;
  final VoidCallback onReceiveDatePressed;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (partners.isEmpty) ...[
            Text(
              'No suppliers yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a supplier first so this purchase is linked to the right partner.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Add supplier',
              onPressed: onAddPartner,
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: selectedPartnerId,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items: partners.map((partner) {
                return DropdownMenuItem<String>(
                  value: partner['id'] as String,
                  child: Text(partner['name'] as String? ?? 'Partner'),
                );
              }).toList(),
              onChanged: onPartnerChanged,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAddPartner,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Partner'),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: TextEditingController(
                    text: AppFormatters.date(orderDate),
                  ),
                  label: 'Order Date',
                  prefixIcon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: onOrderDatePressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: TextEditingController(
                    text: AppFormatters.date(receiveDate),
                  ),
                  label: 'Receive Date',
                  prefixIcon: Icons.inventory_rounded,
                  readOnly: true,
                  onTap: onReceiveDatePressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: noteController,
            label: 'Additional information',
            hintText: 'Optional note',
            maxLines: 3,
            prefixIcon: Icons.notes_rounded,
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemsStep extends StatelessWidget {
  const _PurchaseItemsStep({
    required this.partners,
    required this.items,
    required this.lines,
    required this.isOwner,
    required this.selectedItemId,
    required this.selectedAccountId,
    required this.accounts,
    required this.paidAmountController,
    required this.quantityController,
    required this.unitPriceController,
    required this.onAddPartner,
    required this.onAddInventoryItem,
    required this.onAddAccount,
    required this.onItemChanged,
    required this.onAccountChanged,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onPaidAmountChanged,
    required this.onRemoveLine,
    required this.onAddLine,
    required this.total,
  });

  final List<Map<String, dynamic>> partners;
  final List<Map<String, dynamic>> items;
  final List<_PurchaseLineDraft> lines;
  final bool isOwner;
  final String? selectedItemId;
  final String? selectedAccountId;
  final List<Map<String, dynamic>> accounts;
  final TextEditingController paidAmountController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final VoidCallback onAddPartner;
  final VoidCallback onAddInventoryItem;
  final VoidCallback onAddAccount;
  final ValueChanged<String?> onItemChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<String> onUnitPriceChanged;
  final ValueChanged<String> onPaidAmountChanged;
  final ValueChanged<_PurchaseLineDraft> onRemoveLine;
  final VoidCallback onAddLine;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.isEmpty) ...[
                Text(
                  'No inventory items yet.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first item before recording a purchase.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Add Inventory Item',
                  onPressed: onAddInventoryItem,
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: 'Item',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['name'] as String? ?? 'Item'),
                    );
                  }).toList(),
                  onChanged: onItemChanged,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddInventoryItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add new item'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: quantityController,
                        label: 'Quantity',
                        hintText: '1',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.numbers_rounded,
                        onChanged: onQuantityChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: unitPriceController,
                        label: 'Unit price',
                        hintText: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.attach_money_rounded,
                        onChanged: onUnitPriceChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onAddLine,
                  child: const Text('Add Item'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase Items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (lines.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No items added yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick an item above and tap Add Item. If you still need a supplier, go back and add one there.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    if (partners.isEmpty)
                      OutlinedButton.icon(
                        onPressed: onAddPartner,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add supplier'),
                      ),
                  ],
                )
              else
                ...lines.map((line) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.itemName),
                    subtitle: Text(
                      '${line.quantity} × ${AppFormatters.currency(line.unitPrice)}',
                    ),
                    trailing: IconButton(
                      onPressed: () => onRemoveLine(line),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.currency(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.navy,
                          ),
                    ),
                  ],
                ),
              ),
              if (isOwner) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: paidAmountController,
                  label: 'Amount paid now',
                  hintText: '0',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onPaidAmountChanged,
                ),
                const SizedBox(height: 14),
                if (accounts.isEmpty)
                  AppSurfaceCard(
                    color: AppColors.mintSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No account found for payments.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a cash or bank account so outgoing money is saved correctly.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Add account',
                          onPressed: onAddAccount,
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Pay from account',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account['account_id'] as String,
                        child: Text(account['account_name'] as String? ?? 'Account'),
                      );
                    }).toList(),
                    onChanged: onAccountChanged,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseLineDraft {
  const _PurchaseLineDraft({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final String itemName;
  final double quantity;
  final double unitPrice;
}
