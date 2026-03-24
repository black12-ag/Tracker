import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';
import 'package:liquid_soap_tracker/features/production/widgets/sheets/production_entry_detail_sheet.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/sheets/sales_dispatch_detail_sheet.dart';

class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({
    required this.isOwner,
    required this.recentProduction,
    required this.recentSales,
    super.key,
  });

  final bool isOwner;
  final List<ProductionEntryModel> recentProduction;
  final List<SalesDispatchModel> recentSales;

  Future<void> _showProductionDetails(
    BuildContext context,
    ProductionEntryModel entry,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (context) => ProductionEntryDetailSheet(entry: entry),
    );
  }

  Future<void> _showSalesDetails(
    BuildContext context,
    SalesDispatchModel entry,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (context) =>
          SalesDispatchDetailSheet(dispatch: entry, showMoney: isOwner),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionTitle(
                title: 'Recent production',
                subtitle: 'Latest soap production records',
              ),
              const SizedBox(height: 14),
              if (recentProduction.isEmpty)
                Text(
                  'No production has been recorded yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...recentProduction.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _showProductionDetails(context, entry),
                    title: Text(
                      '${entry.sizeLabel} • ${entry.quantityUnits} units',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(AppFormatters.date(entry.producedOn)),
                    trailing: Text(AppFormatters.liters(entry.sizeLiters)),
                  ),
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
                title: 'Recent sales',
                subtitle: 'Latest customer dispatches',
              ),
              const SizedBox(height: 14),
              if (recentSales.isEmpty)
                Text(
                  'No sales have been recorded yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...recentSales.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _showSalesDetails(context, entry),
                    title: Text(
                      DisplayCleaner.customerName(entry.customer.name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${entry.sizeLabel} • ${entry.quantityUnits} units • ${AppFormatters.shortDate(entry.soldAt)}',
                    ),
                    trailing: Text(
                      DisplayCleaner.status(
                        entry.financeStatus ?? entry.dispatchStatus,
                      ),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
