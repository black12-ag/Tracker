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
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/buttons/attach_finance_button.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/buttons/record_payment_button.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/finance_initial_paid_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/finance_loan_label_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/finance_unit_price_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/payment_amount_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/fields/payment_note_field.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/sections/finance_records_section.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/sections/finance_summary_section.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/sales/controller/sales_controller.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _initialPaidController = TextEditingController();
  final TextEditingController _loanLabelController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _paymentNoteController = TextEditingController();
  String? _selectedPendingDispatchId;
  String? _selectedFinanceId;
  bool _isAttaching = false;
  bool _isRecordingPayment = false;

  @override
  void dispose() {
    _unitPriceController.dispose();
    _initialPaidController.dispose();
    _loanLabelController.dispose();
    _paymentAmountController.dispose();
    _paymentNoteController.dispose();
    super.dispose();
  }

  Future<void> _attachFinance(
    List<SalesDispatchModel> pendingDispatches,
    double defaultCostPerLiter,
  ) async {
    SalesDispatchModel? dispatch;
    for (final item in pendingDispatches) {
      if (item.id == _selectedPendingDispatchId) {
        dispatch = item;
        break;
      }
    }

    if (dispatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a dispatch to attach finance.')),
      );
      return;
    }

    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final initialPaid =
        double.tryParse(_initialPaidController.text.trim()) ?? 0;

    if (unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid unit price.')),
      );
      return;
    }

    final totalAmount = unitPrice * dispatch.quantityUnits;
    if (initialPaid > totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initial payment cannot be more than the sale total.'),
        ),
      );
      return;
    }

    setState(() => _isAttaching = true);
    try {
      final result = await ref
          .read(financeRepositoryProvider)
          .attachFinance(
            dispatch: dispatch,
            unitPrice: unitPrice,
            defaultCostPerLiter: defaultCostPerLiter,
            initialPaid: initialPaid,
            loanLabel: _loanLabelController.text,
          );
      await ref.read(offlineSyncServiceProvider).refreshPendingCount();

      ref
        ..invalidate(financeSummaryProvider)
        ..invalidate(financeRecordsProvider)
        ..invalidate(pendingFinanceDispatchesProvider)
        ..invalidate(salesDispatchesProvider)
        ..invalidate(dashboardBundleProvider);

      _initialPaidController.clear();
      _loanLabelController.clear();

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
        setState(() => _isAttaching = false);
      }
    }
  }

  Future<void> _recordPayment(List<FinanceRecord> records) async {
    FinanceRecord? record;
    for (final item in records) {
      if (item.id == _selectedFinanceId) {
        record = item;
        break;
      }
    }

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a loan to record payment against.'),
        ),
      );
      return;
    }

    final amount = double.tryParse(_paymentAmountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount.')),
      );
      return;
    }

    if (amount > record.balanceAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cannot be more than the remaining balance.'),
        ),
      );
      return;
    }

    setState(() => _isRecordingPayment = true);
    try {
      final result = await ref
          .read(financeRepositoryProvider)
          .recordPayment(
            saleFinanceId: record.id,
            amount: amount,
            note: _paymentNoteController.text,
          );
      await ref.read(offlineSyncServiceProvider).refreshPendingCount();

      ref
        ..invalidate(financeSummaryProvider)
        ..invalidate(financeRecordsProvider)
        ..invalidate(dashboardBundleProvider)
        ..invalidate(salesDispatchesProvider);

      _paymentAmountController.clear();
      _paymentNoteController.clear();

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
        setState(() => _isRecordingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financeSummaryProvider);
    final recordsAsync = ref.watch(financeRecordsProvider);
    final pendingAsync = ref.watch(pendingFinanceDispatchesProvider);
    final bundleAsync = ref.watch(productSetupBundleProvider);

    return AppPageScaffold(
      title: 'Money',
      subtitle: 'Cash in, customer balances, and profit.',
      child: Column(
        children: [
          summaryAsync.when(
            data: (summary) => FinanceSummarySection(summary: summary),
            loading: () => const SizedBox(
              height: 220,
              child: AppLoadingView(message: 'Loading finance summary...'),
            ),
            error: (error, stackTrace) => Text(error.toString()),
          ),
          const SizedBox(height: 18),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'Sales waiting for money',
                  subtitle: 'Pick a sale and add the money details.',
                ),
                const SizedBox(height: 16),
                pendingAsync.when(
                  data: (pendingDispatches) {
                    if (pendingDispatches.isEmpty) {
                      return Text(
                        'All sales already have money added.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }

                    _selectedPendingDispatchId ??= pendingDispatches.first.id;
                    final selected = pendingDispatches.firstWhere(
                      (item) => item.id == _selectedPendingDispatchId,
                    );

                    final defaultCostPerLiter =
                        bundleAsync.value?.defaultCostPerLiter ?? 0;

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPendingDispatchId,
                          decoration: const InputDecoration(
                            labelText: 'Sale',
                            prefixIcon: Icon(Icons.receipt_long_outlined),
                          ),
                          items: pendingDispatches
                              .map(
                                (dispatch) => DropdownMenuItem(
                                  value: dispatch.id,
                                  child: Text(
                                    '${DisplayCleaner.customerName(dispatch.customer.name)} • ${dispatch.sizeLabel} • ${dispatch.quantityUnits} units',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedPendingDispatchId = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            DisplayCleaner.customerName(selected.customer.name),
                          ),
                          subtitle: Text(
                            '${selected.sizeLabel} • ${selected.quantityUnits} units • ${AppFormatters.date(selected.soldAt)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FinanceUnitPriceField(controller: _unitPriceController),
                        const SizedBox(height: 12),
                        FinanceInitialPaidField(
                          controller: _initialPaidController,
                        ),
                        const SizedBox(height: 12),
                        FinanceLoanLabelField(controller: _loanLabelController),
                        const SizedBox(height: 16),
                        Text(
                          'Default cost per liter: ${AppFormatters.currency(defaultCostPerLiter)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        AttachFinanceButton(
                          onPressed: () => _attachFinance(
                            pendingDispatches,
                            defaultCostPerLiter,
                          ),
                          isBusy: _isAttaching,
                        ),
                      ],
                    );
                  },
                  loading: () => const AppLoadingView(
                    message: 'Loading pending dispatches...',
                  ),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'Add payment',
                  subtitle: 'Choose a customer balance and record new money.',
                ),
                const SizedBox(height: 16),
                recordsAsync.when(
                  data: (records) {
                    final openRecords = records
                        .where((record) => record.balanceAmount > 0)
                        .toList();

                    if (openRecords.isEmpty) {
                      return Text(
                        'No customer balances are open right now.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }

                    _selectedFinanceId =
                        openRecords.any((item) => item.id == _selectedFinanceId)
                        ? _selectedFinanceId
                        : openRecords.first.id;
                    final selected = openRecords.firstWhere(
                      (item) => item.id == _selectedFinanceId,
                    );

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFinanceId,
                          decoration: const InputDecoration(
                            labelText: 'Customer balance',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          items: openRecords
                              .map(
                                (record) => DropdownMenuItem(
                                  value: record.id,
                                  child: Text(
                                    '${DisplayCleaner.customerName(record.customerName)} • ${AppFormatters.currency(record.balanceAmount)}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedFinanceId = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            DisplayCleaner.customerName(selected.customerName),
                          ),
                          subtitle: Text(
                            'Outstanding: ${AppFormatters.currency(selected.balanceAmount)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        PaymentAmountField(
                          controller: _paymentAmountController,
                        ),
                        const SizedBox(height: 12),
                        PaymentNoteField(controller: _paymentNoteController),
                        const SizedBox(height: 12),
                        RecordPaymentButton(
                          onPressed: () => _recordPayment(openRecords),
                          isBusy: _isRecordingPayment,
                        ),
                      ],
                    );
                  },
                  loading: () => const AppLoadingView(
                    message: 'Loading finance records...',
                  ),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          recordsAsync.when(
            data: (records) => FinanceRecordsSection(records: records),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => Text(error.toString()),
          ),
        ],
      ),
    );
  }
}
