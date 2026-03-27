import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/dashboard/models/dashboard_bundle.dart';

final dashboardBundleProvider = FutureProvider<DashboardBundle>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    throw StateError('No signed-in user found.');
  }

  final bundle = await ref.watch(trackerRepositoryProvider).fetchHomeBundle(
        owner: profile.isOwner,
      );

  return DashboardBundle(
    summary: Map<String, dynamic>.from(bundle['summary'] as Map? ?? const {}),
    recentSales: ((bundle['recent_sales'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
    recentPurchases: ((bundle['recent_purchases'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
  );
});
