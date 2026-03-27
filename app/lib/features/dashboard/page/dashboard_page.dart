import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_error_view.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/dashboard/widgets/sections/dashboard_activity_section.dart';
import 'package:liquid_soap_tracker/features/dashboard/widgets/sections/dashboard_metrics_section.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    required this.profile,
    required this.onMenuPressed,
    required this.onOpenSales,
    required this.onOpenPurchased,
    required this.onOpenInventory,
    required this.onOpenAccounts,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;
  final VoidCallback onOpenSales;
  final VoidCallback onOpenPurchased;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(dashboardBundleProvider);

    return bundleAsync.when(
      data: (bundle) => ReferencePageScaffold(
        title: 'Home',
        onMenuPressed: onMenuPressed,
        showBottomNavigation: false,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardBundleProvider),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            DashboardMetricsSection(
              bundle: bundle,
              isOwner: profile.isOwner,
              onOpenSales: onOpenSales,
              onOpenPurchased: onOpenPurchased,
              onOpenInventory: onOpenInventory,
              onOpenAccounts: onOpenAccounts,
            ),
            const SizedBox(height: 18),
            DashboardActivitySection(
              recentSales: bundle.recentSales,
              recentPurchases: bundle.recentPurchases,
            ),
          ],
        ),
      ),
      loading: () => ReferencePageScaffold(
        title: 'Home',
        onMenuPressed: onMenuPressed,
        showBottomNavigation: false,
        child: ReferenceDashboardSkeleton(showMoney: profile.isOwner),
      ),
      error: (error, stackTrace) => Scaffold(
        body: AppErrorView(
          title: 'Home unavailable',
          message: error.toString(),
          actionLabel: 'Reload',
          onPressed: () => ref.invalidate(dashboardBundleProvider),
        ),
      ),
    );
  }
}
