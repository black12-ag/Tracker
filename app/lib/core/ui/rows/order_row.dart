import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});
  final String status;

  /// Returns display text for status (capitalize first letter, replace underscores with spaces)
  static String _label(String s) {
    if (s.isEmpty) return s;
    return s.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns color for status badge
  static Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'received':
      case 'completed':
      case 'active':
        return AppColors.mint;
      case 'draft':
      case 'pending':
        return AppColors.warmGray;
      case 'overdue':
      case 'cancelled':
      case 'canceled':
        return AppColors.danger;
      case 'partial':
      case 'partially_paid':
        return AppColors.warning;
      default:
        return AppColors.warmGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum OrderRowType { sales, purchase }

class OrderRow extends StatelessWidget {
  const OrderRow({
    required this.orderCode,
    required this.partnerName,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
    required this.onTap,
    super.key,
  });

  final String orderCode;
  final String partnerName;
  final DateTime date;
  final double amount;
  final String status;
  final OrderRowType type;
  final VoidCallback onTap;

  /// Formats date as "Apr 30"
  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  /// Formats amount with thousand separators, no decimals (e.g. "1,234")
  String _formatAmount(double v) {
    if (v >= 1000) {
      return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = type == OrderRowType.sales ? AppColors.navy : AppColors.mint;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${partnerName}  •  ${_formatDate(date)}',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(amount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
