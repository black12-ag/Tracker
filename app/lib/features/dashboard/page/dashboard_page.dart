import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/ui/layout/app_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_error_view.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_loading_view.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/dashboard/widgets/sections/dashboard_activity_section.dart';
import 'package:liquid_soap_tracker/features/dashboard/widgets/sections/dashboard_metrics_section.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    required this.profile,
    required this.onSignOut,
    required this.onOpenProduct,
    required this.onOpenProduction,
    required this.onOpenSales,
    super.key,
    this.onOpenMoney,
  });

  final AppProfile profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenProduct;
  final VoidCallback onOpenProduction;
  final VoidCallback onOpenSales;
  final VoidCallback? onOpenMoney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(dashboardBundleProvider);

    return bundleAsync.when(
      data: (bundle) => AppPageScaffold(
        title: 'Hello, ${profile.displayName}',
        subtitle: 'Track today in one simple place.',
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'logout') {
              await onSignOut();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              title: bundle.productName,
              subtitle: 'Tap a card to open what you need.',
              trailing: TextButton.icon(
                onPressed: onOpenProduct,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Sizes'),
              ),
            ),
            const SizedBox(height: 18),
            DashboardMetricsSection(
              bundle: bundle,
              isOwner: profile.isOwner,
              onOpenProduct: onOpenProduct,
              onOpenProduction: onOpenProduction,
              onOpenSales: onOpenSales,
              onOpenMoney: onOpenMoney,
            ),
            const SizedBox(height: 18),
            DashboardActivitySection(
              isOwner: profile.isOwner,
              recentProduction: bundle.recentProduction,
              recentSales: bundle.recentSales,
            ),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: AppLoadingView(message: 'Loading dashboard...')),
      error: (error, stackTrace) => Scaffold(
        body: AppErrorView(
          title: 'Dashboard unavailable',
          message: error.toString(),
          actionLabel: 'Reload',
          onPressed: () => ref.invalidate(dashboardBundleProvider),
        ),
      ),
    );
  }
}
