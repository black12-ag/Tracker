import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';

class SalesDispatchDetailSheet extends StatelessWidget {
  const SalesDispatchDetailSheet({
    required this.dispatch,
    required this.showMoney,
    super.key,
  });

  final SalesDispatchModel dispatch;
  final bool showMoney;

  @override
  Widget build(BuildContext context) {
    final note = DisplayCleaner.note(dispatch.notes);

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
            Text('Sale details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Customer'),
              subtitle: Text(
                DisplayCleaner.customerName(dispatch.customer.name),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Size'),
              subtitle: Text(dispatch.sizeLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quantity'),
              subtitle: Text(AppFormatters.units(dispatch.quantityUnits)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(AppFormatters.dateTime(dispatch.soldAt)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Status'),
              subtitle: Text(
                DisplayCleaner.status(
                  dispatch.financeStatus ?? dispatch.dispatchStatus,
                ),
              ),
            ),
            if (showMoney && dispatch.totalAmount != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sale amount'),
                subtitle: Text(AppFormatters.currency(dispatch.totalAmount!)),
              ),
            if (showMoney && dispatch.balanceAmount != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Balance left'),
                subtitle: Text(AppFormatters.currency(dispatch.balanceAmount!)),
              ),
            if (note != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notes'),
                subtitle: Text(note),
              ),
          ],
        ),
      ),
    );
  }
}
