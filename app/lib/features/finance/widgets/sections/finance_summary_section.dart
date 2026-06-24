import 'package:flutter/material.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/core/ui/cards/app_metric_card.dart';
import 'package:tracker/core/utils/formatters.dart';
import 'package:tracker/features/finance/models/finance_summary.dart';

class FinanceSummarySection extends StatelessWidget {
  const FinanceSummarySection({required this.summary, super.key});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final profitIsPositive = summary.netProfit >= 0;
    final cards = [
      AppMetricCard(
        label: 'Cash in',
        value: AppFormatters.currency(summary.totalPaid),
        animatedValue: summary.totalPaid,
        valueFormatter: AppFormatters.currency,
        accentColor: AppColors.mint,
      ),
      AppMetricCard(
        label: 'Customers owe',
        value: AppFormatters.currency(summary.totalBalance),
        animatedValue: summary.totalBalance,
        valueFormatter: AppFormatters.currency,
        accentColor: summary.totalBalance > 0
            ? AppColors.warning
            : AppColors.warmGray,
      ),
      AppMetricCard(
        label: 'Profit',
        value: AppFormatters.currency(summary.netProfit),
        animatedValue: summary.netProfit,
        valueFormatter: AppFormatters.currency,
        accentColor: profitIsPositive ? AppColors.mint : AppColors.danger,
        subtitle: '${summary.openLoans} balances open',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(width: halfWidth, child: cards[0]),
            SizedBox(width: halfWidth, child: cards[1]),
            SizedBox(width: constraints.maxWidth, child: cards[2]),
          ],
        );
      },
    );
  }
}
