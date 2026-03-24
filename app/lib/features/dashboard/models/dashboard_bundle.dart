import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';

class DashboardBundle {
  const DashboardBundle({
    required this.productName,
    required this.inventory,
    required this.todayProductionUnits,
    required this.todaySalesUnits,
    required this.recentProduction,
    required this.recentSales,
    this.financeSummary,
  });

  final String productName;
  final List<ProductSizeSetting> inventory;
  final int todayProductionUnits;
  final int todaySalesUnits;
  final List<ProductionEntryModel> recentProduction;
  final List<SalesDispatchModel> recentSales;
  final FinanceSummary? financeSummary;
}
