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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: two most important metrics side-by-side
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Items in stock',
                value: bundle.totalStockUnits.toStringAsFixed(
                  bundle.totalStockUnits ==
                          bundle.totalStockUnits.roundToDouble()
                      ? 0
                      : 1,
                ),
                subtitle: '${bundle.inventoryItemsCount} inventory items',
                accentColor: AppColors.navy,
                onTap: onOpenInventory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppMetricCard(
                label: 'Sales orders',
                value: '${bundle.totalSalesOrders}',
                subtitle: 'Open sales list',
                accentColor: AppColors.navy,
                onTap: onOpenSales,
              ),
            ),
          ],
        ),

        // Owner-only financial strip
        if (isOwner) ...[
          const SizedBox(height: 16),
          AppSurfaceCard(
            color: AppColors.mintSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue — largest, navy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.warmGray),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.currency(bundle.revenue),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Profit — medium, mint
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.warmGray),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.currency(bundle.netProfit),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mint,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Overdue — smallest, danger color
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overdue',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.warmGray),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bundle.overdueOrdersCount == 0
                            ? '0'
                            : AppFormatters.currency(bundle.overdueBalanceTotal),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Bottom row: purchase orders + overdue count
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppMetricCard(
                label: 'Purchase orders',
                value: '${bundle.totalPurchaseOrders}',
                subtitle: 'Open purchased list',
                accentColor: AppColors.mint,
                onTap: onOpenPurchased,
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppMetricCard(
                  label: 'Overdue balances',
                  value: '${bundle.overdueOrdersCount}',
                  subtitle: bundle.overdueOrdersCount == 0
                      ? 'No late customers'
                      : AppFormatters.currency(bundle.overdueBalanceTotal),
                  accentColor: AppColors.navy,
                  onTap: onOpenAccounts,
                ),
              ),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
