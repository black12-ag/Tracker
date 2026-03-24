import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_metric_card.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';

class FinanceSummarySection extends StatelessWidget {
  const FinanceSummarySection({required this.summary, super.key});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AppMetricCard(
        label: 'Cash in',
        value: AppFormatters.currency(summary.totalPaid),
      ),
      AppMetricCard(
        label: 'Customers owe',
        value: AppFormatters.currency(summary.totalBalance),
      ),
      AppMetricCard(
        label: 'Profit',
        value: AppFormatters.currency(summary.netProfit),
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
