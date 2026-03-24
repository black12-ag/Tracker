import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/layout/app_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_loading_view.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/finance/controller/finance_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/sales/controller/sales_controller.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/buttons/save_sale_button.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/sections/sales_form_section.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/sheets/sales_dispatch_detail_sheet.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _loanLabelController = TextEditingController();
  String? _selectedSizeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_refreshAdvancedFields);
    _unitPriceController.addListener(_refreshAdvancedFields);
    _amountPaidController.addListener(_refreshAdvancedFields);
  }

  void _refreshAdvancedFields() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _shouldShowLoanLabel(ProductSetupBundle bundle) {
    if (!widget.profile.isOwner || _selectedSizeId == null) {
      return false;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final amountPaidText = _amountPaidController.text.trim();
    if (quantity <= 0 || unitPrice <= 0 || amountPaidText.isEmpty) {
      return false;
    }

    final amountPaid = double.tryParse(amountPaidText) ?? 0;
    final total = quantity * unitPrice;
    return total > 0 && amountPaid < total;
  }

  @override
  void dispose() {
    _quantityController.removeListener(_refreshAdvancedFields);
    _unitPriceController.removeListener(_refreshAdvancedFields);
    _amountPaidController.removeListener(_refreshAdvancedFields);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _unitPriceController.dispose();
    _amountPaidController.dispose();
    _loanLabelController.dispose();
    super.dispose();
  }

  void _onSizeChanged(String? value, ProductSetupBundle bundle) {
    setState(() => _selectedSizeId = value);
    if (!widget.profile.isOwner || value == null) {
      return;
    }

    final selected = bundle.sizes.firstWhere((size) => size.id == value);
    _unitPriceController.text = selected.unitPrice == null
        ? ''
        : selected.unitPrice!.toStringAsFixed(2);
  }

  Future<void> _save(ProductSetupBundle bundle) async {
    final quantityUnits = int.tryParse(_quantityController.text.trim()) ?? 0;
    final sizeId = _selectedSizeId;

    if (_customerNameController.text.trim().isEmpty ||
        sizeId == null ||
        quantityUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer, size, and quantity are required.'),
        ),
      );
      return;
    }

    final selectedSize = bundle.sizes.firstWhere((size) => size.id == sizeId);
    final unitPrice = widget.profile.isOwner
        ? double.tryParse(_unitPriceController.text.trim()) ?? 0
        : null;
    final initialPaid = widget.profile.isOwner
        ? double.tryParse(_amountPaidController.text.trim()) ?? 0
        : 0.0;

    if (widget.profile.isOwner) {
      if ((unitPrice ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid unit price.')),
        );
        return;
      }

      final totalAmount = (unitPrice ?? 0) * quantityUnits;
      if (initialPaid > totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount paid cannot be more than the total sale.'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final result = await ref
          .read(salesRepositoryProvider)
          .createDispatch(
            userId: widget.profile.id,
            size: selectedSize,
            quantityUnits: quantityUnits,
            customerName: _customerNameController.text,
            customerPhone: _customerPhoneController.text,
            notes: _notesController.text,
            owner: widget.profile.isOwner,
            unitPrice: unitPrice,
            defaultCostPerLiter: widget.profile.isOwner
                ? (bundle.defaultCostPerLiter ?? 0)
                : null,
            initialPaid: initialPaid,
            loanLabel: widget.profile.isOwner
                ? _loanLabelController.text
                : null,
          );
      await ref.read(offlineSyncServiceProvider).refreshPendingCount();

      ref
        ..invalidate(salesDispatchesProvider)
        ..invalidate(productSetupBundleProvider)
        ..invalidate(dashboardBundleProvider)
        ..invalidate(financeSummaryProvider)
        ..invalidate(financeRecordsProvider)
        ..invalidate(pendingFinanceDispatchesProvider);

      _customerNameController.clear();
      _customerPhoneController.clear();
      _quantityController.clear();
      _notesController.clear();
      _amountPaidController.clear();
      _loanLabelController.clear();
      if (widget.profile.isOwner) {
        _unitPriceController.text = (selectedSize.unitPrice ?? 0)
            .toStringAsFixed(2);
        if (selectedSize.unitPrice == null) {
          _unitPriceController.clear();
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
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

  Future<void> _showDetails(BuildContext context, SalesDispatchModel item) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (context) => SalesDispatchDetailSheet(
        dispatch: item,
        showMoney: widget.profile.isOwner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(productSetupBundleProvider);
    final salesAsync = ref.watch(salesDispatchesProvider);

    return AppPageScaffold(
      title: 'Sales',
      subtitle: widget.profile.isOwner
          ? 'Add a sale and any money paid now.'
          : 'Add a sale quickly and keep money hidden.',
      child: bundleAsync.when(
        data: (bundle) {
          _selectedSizeId ??= bundle.sizes.isNotEmpty
              ? bundle.sizes.first.id
              : null;
          if (widget.profile.isOwner &&
              _unitPriceController.text.isEmpty &&
              _selectedSizeId != null) {
            final selected = bundle.sizes.firstWhere(
              (size) => size.id == _selectedSizeId,
            );
            _unitPriceController.text = selected.unitPrice == null
                ? ''
                : selected.unitPrice!.toStringAsFixed(2);
          }

          return Column(
            children: [
              SalesFormSection(
                sizeOptions: bundle.sizes,
                selectedSizeId: _selectedSizeId,
                onChangedSize: (value) => _onSizeChanged(value, bundle),
                customerNameController: _customerNameController,
                customerPhoneController: _customerPhoneController,
                quantityController: _quantityController,
                notesController: _notesController,
                isOwner: widget.profile.isOwner,
                unitPriceController: _unitPriceController,
                amountPaidController: _amountPaidController,
                loanLabelController: _loanLabelController,
                showLoanLabel: _shouldShowLoanLabel(bundle),
              ),
              const SizedBox(height: 18),
              SaveSaleButton(onPressed: () => _save(bundle), isBusy: _isSaving),
              const SizedBox(height: 18),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle(
                      title: 'Recent sales',
                      subtitle: 'Tap any row to see more',
                    ),
                    const SizedBox(height: 14),
                    salesAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Text(
                            'No sales have been recorded yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }

                        return Column(
                          children: items
                              .map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () => _showDetails(context, item),
                                  title: Text(
                                    '${DisplayCleaner.customerName(item.customer.name)} • ${item.quantityUnits} units',
                                  ),
                                  subtitle: Text(
                                    '${item.sizeLabel} • ${AppFormatters.date(item.soldAt)}',
                                  ),
                                  trailing: Text(
                                    DisplayCleaner.status(
                                      widget.profile.isOwner
                                          ? (item.financeStatus ?? 'recorded')
                                          : item.dispatchStatus,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const AppLoadingView(
                        message: 'Loading recent sales...',
                      ),
                      error: (error, stackTrace) => Text(error.toString()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 220,
          child: AppLoadingView(message: 'Loading sales setup...'),
        ),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }
}
