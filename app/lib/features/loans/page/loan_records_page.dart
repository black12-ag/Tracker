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
import 'package:url_launcher/url_launcher.dart';

class LoanRecordsPage extends ConsumerStatefulWidget {
  const LoanRecordsPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<LoanRecordsPage> createState() => _LoanRecordsPageState();
}

class _LoanRecordsPageState extends ConsumerState<LoanRecordsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _alerts = const [];
  List<Map<String, dynamic>> _loans = const [];
  List<Map<String, dynamic>> _partners = const [];
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
      final alerts = await repo.listSalesBalanceAlerts();
      final loans = await repo.listLoanRecords();
      final partners = await repo.listPartners();
      final accounts = await repo.listAccountSummaries();
      if (!mounted) {
        return;
      }
      setState(() {
        _alerts = alerts;
        _loans = loans;
        _partners = partners;
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

  Future<void> _addLoan() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _AddLoanDialog(
        profile: widget.profile,
        partners: _partners,
        accounts: _accounts,
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _recordSalesPayment(Map<String, dynamic> alert) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _RecordSalesPaymentDialog(
        salesAlert: alert,
        accounts: _accounts,
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _markReminder(Map<String, dynamic> alert) async {
    try {
      await ref.read(trackerRepositoryProvider).markSalesOrderReminderSent(
            salesOrderId: alert['sales_order_id'] as String,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder marked and saved.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number found for this customer.')),
      );
      return;
    }

    final cleaned = phone.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Loan Records',
      onMenuPressed: widget.onMenuPressed,
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: _isLoading
          ? const ReferenceListPageSkeleton(
              showSearch: false,
              showTopCard: true,
              itemCount: 6,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSurfaceCard(
                  color: AppColors.mintSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer balances',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _alerts.isEmpty
                            ? 'No unpaid customer balances right now.'
                            : '${_alerts.length} sales still have money left to collect.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_alerts.isEmpty)
                  AppSurfaceCard(
                    child: Text(
                      'Every saved sale is fully paid right now.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  AppSurfaceCard(
                    child: Column(
                      children: _alerts.map((alert) {
                        final overdueLevel =
                            (alert['overdue_level'] as String? ?? 'pending')
                                .toLowerCase();
                        final badgeColor = switch (overdueLevel) {
                          'severe' => AppColors.danger,
                          'late' => AppColors.warning,
                          'upcoming' => AppColors.navy,
                          _ => AppColors.mint,
                        };
                        final daysOverdue =
                            (alert['days_overdue'] as num?)?.toInt() ?? 0;
                        final paymentCount =
                            (alert['payment_count'] as num?)?.toInt() ?? 0;
                        final phone = alert['customer_phone'] as String?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert['customer_name'] as String? ??
                                              'Customer',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        if (phone != null && phone.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(phone),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Order ${alert['order_code'] ?? ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          'Due ${AppFormatters.date(DateTime.tryParse((alert['due_date'] as String?) ?? '') ?? DateTime.now())}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _StatusChip(
                                              label: overdueLevel == 'severe'
                                                  ? 'Severely late'
                                                  : overdueLevel == 'late'
                                                      ? 'Late'
                                                      : overdueLevel == 'upcoming'
                                                          ? 'Upcoming'
                                                          : 'Pending',
                                              color: badgeColor,
                                            ),
                                            _StatusChip(
                                              label: paymentCount == 1
                                                  ? '1 payment'
                                                  : '$paymentCount payments',
                                              color: AppColors.navy,
                                            ),
                                            if (daysOverdue > 0)
                                              _StatusChip(
                                                label: '$daysOverdue days overdue',
                                                color: AppColors.warning,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.currency(
                                          (alert['balance_amount'] as num?)
                                                  ?.toDouble() ??
                                              0,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: AppColors.navy,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid ${AppFormatters.currency((alert['paid_amount'] as num?)?.toDouble() ?? 0)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _callCustomer(phone),
                                    icon: const Icon(Icons.call_outlined),
                                    label: const Text('Call'),
                                  ),
                                  PrimaryButton(
                                    label: 'Add payment',
                                    onPressed: () => _recordSalesPayment(alert),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _markReminder(alert),
                                    icon: const Icon(Icons.notifications_active),
                                    label: const Text('Mark reminder'),
                                  ),
                                ],
                              ),
                              if (alert != _alerts.last) const Divider(height: 28),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Manual loan records',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (_loans.isEmpty)
                  AppSurfaceCard(
                    child: Text(
                      'No manual loan records yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  AppSurfaceCard(
                    child: Column(
                      children: _loans.map((loan) {
                        final partner = loan['partners'] is Map
                            ? Map<String, dynamic>.from(loan['partners'] as Map)
                            : const <String, dynamic>{};
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            partner['name'] as String? ?? 'Partner',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${loan['direction'] == 'we_gave_them' ? 'We gave them' : 'They gave us'} • ${AppFormatters.date(DateTime.tryParse((loan['record_date'] as String?) ?? '') ?? DateTime.now())}',
                          ),
                          trailing: Text(
                            AppFormatters.currency(
                              (loan['balance_amount'] as num?)?.toDouble() ?? 0,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RecordSalesPaymentDialog extends ConsumerStatefulWidget {
  const _RecordSalesPaymentDialog({
    required this.salesAlert,
    required this.accounts,
  });

  final Map<String, dynamic> salesAlert;
  final List<Map<String, dynamic>> accounts;

  @override
  ConsumerState<_RecordSalesPaymentDialog> createState() =>
      _RecordSalesPaymentDialogState();
}

class _RecordSalesPaymentDialogState
    extends ConsumerState<_RecordSalesPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  DateTime _paymentDate = DateTime.now();
  String? _accountId;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the account that received this payment.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final maxAmount =
        (widget.salesAlert['balance_amount'] as num?)?.toDouble() ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount must be greater than 0.')),
      );
      return;
    }
    if (amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount is greater than the remaining balance.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(trackerRepositoryProvider).recordSalesOrderPayment(
            salesOrderId: widget.salesAlert['sales_order_id'] as String,
            accountId: _accountId!,
            amount: amount,
            paymentDate: _paymentDate,
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
      title: Text(
        'Add Payment for ${widget.salesAlert['customer_name'] ?? 'Customer'}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: TextEditingController(
                text: AppFormatters.currency(
                  (widget.salesAlert['balance_amount'] as num?)?.toDouble() ?? 0,
                ),
              ),
              label: 'Remaining balance',
              readOnly: true,
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: 'Payment amount',
              hintText: '0',
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(
                labelText: 'Receive to account',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
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
              controller: TextEditingController(
                text: AppFormatters.date(_paymentDate),
              ),
              label: 'Payment date',
              readOnly: true,
              prefixIcon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Note',
              hintText: 'Optional',
              maxLines: 3,
              prefixIcon: Icons.notes_rounded,
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

class _AddLoanDialog extends ConsumerStatefulWidget {
  const _AddLoanDialog({
    required this.profile,
    required this.partners,
    required this.accounts,
  });

  final AppProfile profile;
  final List<Map<String, dynamic>> partners;
  final List<Map<String, dynamic>> accounts;

  @override
  ConsumerState<_AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends ConsumerState<_AddLoanDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String _direction = 'they_gave_us';
  String? _partnerId;
  String? _accountId;
  final DateTime _recordDate = DateTime.now();
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
    if (_partnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a partner.')),
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
      await ref.read(trackerRepositoryProvider).createLoanRecord(
            createdBy: widget.profile.id,
            partnerId: _partnerId!,
            direction: _direction,
            recordDate: _recordDate,
            amount: amount,
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
      title: const Text('Recording New'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'they_gave_us',
                  label: Text('They gave us'),
                ),
                ButtonSegment(
                  value: 'we_gave_them',
                  label: Text('We gave them'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (value) {
                setState(() => _direction = value.first);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _partnerId,
              decoration: const InputDecoration(labelText: 'Primary Partner'),
              items: widget.partners.map((partner) {
                return DropdownMenuItem<String>(
                  value: partner['id'] as String,
                  child: Text(partner['name'] as String? ?? 'Partner'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _partnerId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Record From'),
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
              controller: _amountController,
              label: 'Amount',
              hintText: 'Enter amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Note',
              hintText: 'Your note here',
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
