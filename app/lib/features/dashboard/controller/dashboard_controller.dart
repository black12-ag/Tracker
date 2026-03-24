import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/dashboard/models/dashboard_bundle.dart';

final dashboardBundleProvider = FutureProvider<DashboardBundle>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    throw StateError('No signed-in user found.');
  }

  final today = DateTime.now();
  final productBundle = await ref
      .watch(productRepositoryProvider)
      .fetchBundle(owner: profile.isOwner);
  final todayProductionUnits = await ref
      .watch(productionRepositoryProvider)
      .fetchTotalProducedOn(today);
  final todaySalesUnits = await ref
      .watch(salesRepositoryProvider)
      .fetchTotalSoldOn(today);
  final productionEntries = await ref
      .watch(productionRepositoryProvider)
      .fetchRecentEntries(limit: 5);
  final salesDispatches = await ref
      .watch(salesRepositoryProvider)
      .fetchRecentDispatches(owner: profile.isOwner, limit: 5);
  final financeSummary = profile.isOwner
      ? await ref.watch(financeRepositoryProvider).fetchSummary()
      : null;

  return DashboardBundle(
    productName: productBundle.productName,
    inventory: productBundle.sizes,
    todayProductionUnits: todayProductionUnits,
    todaySalesUnits: todaySalesUnits,
    recentProduction: productionEntries,
    recentSales: salesDispatches,
    financeSummary: financeSummary,
  );
});
