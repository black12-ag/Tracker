import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class InventoryRow extends StatelessWidget {
  const InventoryRow({
    required this.name,
    required this.sku,
    required this.unitType,
    required this.stockQty,
    required this.price,
    required this.onTap,
    super.key,
    this.lowStockThreshold = 10,
  });

  final String name;
  final String sku;
  final String unitType;
  final int stockQty;
  final double price;
  final VoidCallback onTap;
  final int lowStockThreshold;

  /// Formats price with thousand separators, no decimals (e.g. "1,234")
  String _formatPrice(double v) {
    if (v >= 1000) {
      return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return v.toStringAsFixed(0);
  }

  /// Returns color based on stock level
  Color _stockColor() {
    if (stockQty <= 0) return AppColors.danger;
    if (stockQty <= lowStockThreshold) return AppColors.warning;
    return AppColors.navy;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sku.isNotEmpty ? sku : "—"}  •  $unitType',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warmGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$stockQty',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _stockColor(),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'in stock',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.warmGray,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'per unit',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.warmGray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
