import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';

class FinanceRecordDetailSheet extends StatelessWidget {
  const FinanceRecordDetailSheet({required this.record, super.key});

  final FinanceRecord record;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              'Balance details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Customer'),
              subtitle: Text(DisplayCleaner.customerName(record.customerName)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Status'),
              subtitle: Text(DisplayCleaner.status(record.financeStatus)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Total sale'),
              subtitle: Text(AppFormatters.currency(record.totalAmount)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid'),
              subtitle: Text(AppFormatters.currency(record.paidAmount)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Balance left'),
              subtitle: Text(AppFormatters.currency(record.balanceAmount)),
            ),
            if (record.loanLabel != null && record.loanLabel!.trim().isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Balance note'),
                subtitle: Text(record.loanLabel!.trim()),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(AppFormatters.dateTime(record.soldAt)),
            ),
          ],
        ),
      ),
    );
  }
}
