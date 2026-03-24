import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/widgets/sheets/finance_record_detail_sheet.dart';

class FinanceRecordsSection extends StatelessWidget {
  const FinanceRecordsSection({required this.records, super.key});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Customer balances',
            subtitle: 'Tap any row to see more',
          ),
          const SizedBox(height: 14),
          if (records.isEmpty)
            Text(
              'No finance records yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...records.map(
              (record) => ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: false,
                  builder: (context) =>
                      FinanceRecordDetailSheet(record: record),
                ),
                title: Text(DisplayCleaner.customerName(record.customerName)),
                subtitle: Text(
                  '${record.sizeLabel} • ${record.quantityUnits} units • ${AppFormatters.date(record.soldAt)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.currency(record.balanceAmount),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      DisplayCleaner.status(record.financeStatus),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
