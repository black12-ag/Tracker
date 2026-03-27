import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_metric_card.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/dashboard/models/dashboard_bundle.dart';

class DashboardMetricsSection extends StatelessWidget {
  const DashboardMetricsSection({
    required this.bundle,
    required this.isOwner,
    required this.onOpenSales,
    required this.onOpenPurchased,
    required this.onOpenInventory,
    required this.onOpenAccounts,
    super.key,
  });

  final DashboardBundle bundle;
  final bool isOwner;
  final VoidCallback onOpenSales;
  final VoidCallback onOpenPurchased;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      AppMetricCard(
        label: 'Items in stock',
        value: bundle.totalStockUnits.toStringAsFixed(
          bundle.totalStockUnits == bundle.totalStockUnits.roundToDouble() ? 0 : 1,
        ),
        subtitle: '${bundle.inventoryItemsCount} inventory items',
        accentColor: AppColors.navy,
        onTap: onOpenInventory,
      ),
      AppMetricCard(
        label: 'Sales orders',
        value: '${bundle.totalSalesOrders}',
        subtitle: 'Open sales list',
        accentColor: AppColors.navy,
        onTap: onOpenSales,
      ),
      AppMetricCard(
        label: 'Purchase orders',
        value: '${bundle.totalPurchaseOrders}',
        subtitle: 'Open purchased list',
        accentColor: AppColors.mint,
        onTap: onOpenPurchased,
      ),
      if (isOwner)
        AppMetricCard(
          label: 'Total assets',
          value: AppFormatters.currency(bundle.totalAssets),
          subtitle: 'Cash, banks, stock, and collectible loans',
          accentColor: AppColors.mint,
          onTap: onOpenAccounts,
        ),
      if (isOwner)
        AppMetricCard(
          label: 'Overdue balances',
          value: '${bundle.overdueOrdersCount}',
          subtitle: bundle.overdueOrdersCount == 0
              ? 'No late customers right now'
              : '${AppFormatters.currency(bundle.overdueBalanceTotal)} still overdue',
          accentColor: AppColors.navy,
          onTap: onOpenAccounts,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards) SizedBox(width: itemWidth, child: card),
              ],
            );
          },
        ),
        if (isOwner) ...[
          const SizedBox(height: 16),
          AppSurfaceCard(
            color: AppColors.mintSoft,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 120,
                  child: _SummaryMiniTile(
                    label: 'Cash in',
                    value: AppFormatters.currency(bundle.collectedMoney),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _SummaryMiniTile(
                    label: 'Revenue',
                    value: AppFormatters.currency(bundle.revenue),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _SummaryMiniTile(
                    label: 'Profit',
                    value: AppFormatters.currency(bundle.netProfit),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: _SummaryMiniTile(
                    label: 'Overdue',
                    value: bundle.overdueOrdersCount == 0
                        ? '0'
                        : AppFormatters.currency(bundle.overdueBalanceTotal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryMiniTile extends StatelessWidget {
  const _SummaryMiniTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
