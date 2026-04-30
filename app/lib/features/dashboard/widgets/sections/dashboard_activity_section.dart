import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/rows/order_row.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';

class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({
    required this.recentSales,
    required this.recentPurchases,
    super.key,
  });

  final List<Map<String, dynamic>> recentSales;
  final List<Map<String, dynamic>> recentPurchases;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActivityCard(
          title: 'Recent sales',
          rows: recentSales,
          type: OrderRowType.sales,
        ),
        const SizedBox(height: 16),
        _ActivityCard(
          title: 'Recent purchases',
          rows: recentPurchases,
          type: OrderRowType.purchase,
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.rows,
    required this.type,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final OrderRowType type;

  Future<void> _showDetails(BuildContext context, Map<String, dynamic> row) {
    final partner = row['partners'] is Map
        ? Map<String, dynamic>.from(row['partners'] as Map)
        : const <String, dynamic>{};
    final itemKey = type == OrderRowType.sales
        ? 'sales_order_items'
        : 'purchase_order_items';
    final items = ((row[itemKey] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row['order_code'] as String? ?? 'Order details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                partner['name'] as String? ?? 'No partner selected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${row['status'] ?? 'draft'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${AppFormatters.currency((row['total_amount'] as num?)?.toDouble() ?? 0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final product = item['inventory_items'] is Map
                      ? Map<String, dynamic>.from(
                          item['inventory_items'] as Map)
                      : const <String, dynamic>{};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] as String? ?? 'Item',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          '${(item['quantity'] as num?)?.toDouble() ?? 0} × ${AppFormatters.currency((item['unit_price'] as num?)?.toDouble() ?? 0)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              'Nothing recorded yet.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.warmGray),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final partner = row['partners'] is Map
                  ? Map<String, dynamic>.from(row['partners'] as Map)
                  : const <String, dynamic>{};
              final dateStr = row['order_date'] as String?;
              final date =
                  (dateStr != null ? DateTime.tryParse(dateStr) : null) ??
                      DateTime.now();

              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.line,
                    ),
                  OrderRow(
                    orderCode: row['order_code'] as String? ?? 'Order',
                    partnerName:
                        partner['name'] as String? ?? 'No partner',
                    date: date,
                    amount:
                        (row['total_amount'] as num?)?.toDouble() ?? 0,
                    status: row['status'] as String? ?? 'draft',
                    type: type,
                    onTap: () => _showDetails(context, row),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
