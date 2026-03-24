class FinanceSummary {
  const FinanceSummary({
    required this.totalSales,
    required this.totalPaid,
    required this.totalBalance,
    required this.estimatedProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.openLoans,
  });

  const FinanceSummary.empty()
    : totalSales = 0,
      totalPaid = 0,
      totalBalance = 0,
      estimatedProfit = 0,
      totalExpenses = 0,
      netProfit = 0,
      openLoans = 0;

  final double totalSales;
  final double totalPaid;
  final double totalBalance;
  final double estimatedProfit;
  final double totalExpenses;
  final double netProfit;
  final int openLoans;

  factory FinanceSummary.fromMap(Map<String, dynamic> map) {
    return FinanceSummary(
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0,
      totalBalance: (map['total_balance'] as num?)?.toDouble() ?? 0,
      estimatedProfit: (map['estimated_profit'] as num?)?.toDouble() ?? 0,
      totalExpenses: (map['total_expenses'] as num?)?.toDouble() ?? 0,
      netProfit: (map['net_profit'] as num?)?.toDouble() ?? 0,
      openLoans: map['open_loans'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_sales': totalSales,
      'total_paid': totalPaid,
      'total_balance': totalBalance,
      'estimated_profit': estimatedProfit,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'open_loans': openLoans,
    };
  }
}
