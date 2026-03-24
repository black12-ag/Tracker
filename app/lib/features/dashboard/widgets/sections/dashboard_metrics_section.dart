import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/features/dashboard/models/dashboard_bundle.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_metric_card.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';

class DashboardMetricsSection extends StatelessWidget {
  const DashboardMetricsSection({
    required this.bundle,
    required this.isOwner,
    required this.onOpenProduct,
    required this.onOpenProduction,
    required this.onOpenSales,
    super.key,
    this.onOpenMoney,
  });

  final DashboardBundle bundle;
  final bool isOwner;
  final VoidCallback onOpenProduct;
  final VoidCallback onOpenProduction;
  final VoidCallback onOpenSales;
  final VoidCallback? onOpenMoney;

  @override
  Widget build(BuildContext context) {
    final currentStock = bundle.inventory.fold<int>(
      0,
      (sum, size) => sum + size.currentStockUnits,
    );
    final lowStockCount = bundle.inventory
        .where((size) => size.isLowStock)
        .length;
    final cards = <Widget>[
      AppMetricCard(
        label: 'Today production',
        value: AppFormatters.units(bundle.todayProductionUnits),
        subtitle: 'Open production',
        onTap: onOpenProduction,
      ),
      AppMetricCard(
        label: 'Today sales',
        value: AppFormatters.units(bundle.todaySalesUnits),
        subtitle: 'Open sales',
        onTap: onOpenSales,
      ),
      AppMetricCard(
        label: 'Current stock',
        value: AppFormatters.units(currentStock),
        subtitle: lowStockCount == 0
            ? 'All sizes look okay'
            : '$lowStockCount sizes are low',
        onTap: onOpenProduct,
      ),
      if (isOwner)
        AppMetricCard(
          label: 'Cash in',
          value: AppFormatters.currency(
            bundle.financeSummary?.totalPaid ?? 0,
          ),
          subtitle:
              '${bundle.financeSummary?.openLoans ?? 0} balances still open',
          onTap: onOpenMoney,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var index = 0; index < cards.length; index++)
              SizedBox(
                width: cards.length.isOdd && index == cards.length - 1
                    ? constraints.maxWidth
                    : halfWidth,
                child: cards[index],
              ),
          ],
        );
      },
    );
  }
}
