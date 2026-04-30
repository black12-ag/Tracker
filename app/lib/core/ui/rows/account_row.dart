import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.accountName,
    required this.bankName,
    required this.accountType,
    required this.balance,
    required this.onTap,
    super.key,
  });

  final String accountName;
  final String bankName;
  final String accountType;
  final double balance;
  final VoidCallback onTap;

  /// Returns appropriate icon based on account type
  IconData _getIcon(String type) {
    final typeLower = type.toLowerCase();
    if (typeLower.contains('wallet') || typeLower.contains('cash')) {
      return Icons.account_balance_wallet_outlined;
    }
    return Icons.account_balance_outlined;
  }

  /// Formats balance with thousand separators and proper sign
  String _formatBalance(double v) {
    final absValue = v.abs();
    String formatted;
    if (absValue >= 1000) {
      formatted = absValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    } else {
      formatted = absValue.toStringAsFixed(0);
    }
    return v < 0 ? '-$formatted' : formatted;
  }

  /// Returns color based on balance
  Color _balanceColor() {
    return balance <= 0 ? AppColors.warmGray : AppColors.navy;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(accountType);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: AppColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Account info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bankName.isNotEmpty
                        ? '$bankName  •  $accountType'
                        : accountType,
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
            // Balance
            Text(
              _formatBalance(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _balanceColor(),
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
