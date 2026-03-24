import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/dashboard/page/dashboard_page.dart';
import 'package:liquid_soap_tracker/features/finance/page/finance_page.dart';
import 'package:liquid_soap_tracker/features/product_setup/page/product_setup_page.dart';
import 'package:liquid_soap_tracker/features/production/page/production_page.dart';
import 'package:liquid_soap_tracker/features/sales/page/sales_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _goToTab(int value) {
    if (_index == value) {
      return;
    }
    setState(() => _index = value);
  }

  Future<void> _openProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductSetupPage(profile: widget.profile),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final pendingCount = await ref
        .read(localStoreServiceProvider)
        .pendingQueueCount();
    if (pendingCount > 0) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'You have $pendingCount unsynced change${pendingCount == 1 ? '' : 's'}. Go online and let them sync before logging out.',
          ),
        ),
      );
      return;
    }

    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        profile: widget.profile,
        onSignOut: () => _signOut(context),
        onOpenProduct: _openProduct,
        onOpenProduction: () => _goToTab(1),
        onOpenSales: () => _goToTab(2),
        onOpenMoney: widget.profile.isOwner ? () => _goToTab(3) : null,
      ),
      ProductionPage(profile: widget.profile),
      SalesPage(profile: widget.profile),
      if (widget.profile.isOwner) FinancePage(profile: widget.profile),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.science_outlined),
        selectedIcon: Icon(Icons.science),
        label: 'Production',
      ),
      const NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'Sales',
      ),
      if (widget.profile.isOwner)
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Money',
        ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: _index,
              destinations: destinations,
              onDestinationSelected: (value) {
                setState(() => _index = value);
              },
            ),
          ),
        ),
      ),
    );
  }
}
