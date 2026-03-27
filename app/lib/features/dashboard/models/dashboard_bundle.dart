class DashboardBundle {
  const DashboardBundle({
    required this.summary,
    required this.recentSales,
    required this.recentPurchases,
  });

  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> recentSales;
  final List<Map<String, dynamic>> recentPurchases;

  double get totalStockUnits =>
      (summary['total_stock_units'] as num?)?.toDouble() ?? 0;

  double get totalAssets => (summary['total_assets'] as num?)?.toDouble() ?? 0;

  double get totalInBanks =>
      (summary['total_in_banks'] as num?)?.toDouble() ?? 0;

  double get collectibleLoans =>
      (summary['loan_records_collectible'] as num?)?.toDouble() ?? 0;

  double get payableLoans =>
      (summary['loan_records_payable'] as num?)?.toDouble() ?? 0;

  double get netWorth => (summary['net_worth'] as num?)?.toDouble() ?? 0;

  double get profitMargin =>
      (summary['profit_margin'] as num?)?.toDouble() ?? 0;

  double get revenue => (summary['revenue'] as num?)?.toDouble() ?? 0;

  double get collectedMoney =>
      (summary['collected_money'] as num?)?.toDouble() ?? 0;

  double get estimatedProfit =>
      (summary['estimated_profit'] as num?)?.toDouble() ?? 0;

  double get netProfit => (summary['net_profit'] as num?)?.toDouble() ?? 0;

  double get overdueBalanceTotal =>
      (summary['overdue_balance_total'] as num?)?.toDouble() ?? 0;

  int get inventoryItemsCount =>
      (summary['inventory_items_count'] as num?)?.toInt() ?? 0;

  int get totalSalesOrders =>
      (summary['total_sales_orders'] as num?)?.toInt() ?? 0;

  int get totalPurchaseOrders =>
      (summary['total_purchase_orders'] as num?)?.toInt() ?? 0;

  int get overdueOrdersCount =>
      (summary['overdue_orders_count'] as num?)?.toInt() ?? 0;
}
