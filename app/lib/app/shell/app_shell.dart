import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/shell/tracker_drawer.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/layout/tracker_bottom_navigation.dart';
import 'package:liquid_soap_tracker/features/account/page/account_page.dart';
import 'package:liquid_soap_tracker/features/dashboard/page/dashboard_page.dart';
import 'package:liquid_soap_tracker/features/employees/page/employees_page.dart';
import 'package:liquid_soap_tracker/features/expenses/page/expenses_page.dart';
import 'package:liquid_soap_tracker/features/inventory/page/inventory_page.dart';
import 'package:liquid_soap_tracker/features/inventory_adjustment/page/inventory_adjustment_page.dart';
import 'package:liquid_soap_tracker/features/loans/page/loan_records_page.dart';
import 'package:liquid_soap_tracker/features/partners/page/partners_page.dart';
import 'package:liquid_soap_tracker/features/profile/page/profile_page.dart';
import 'package:liquid_soap_tracker/features/purchased/page/purchased_page.dart';
import 'package:liquid_soap_tracker/features/receive/page/receive_page.dart';
import 'package:liquid_soap_tracker/features/reports/page/reports_page.dart';
import 'package:liquid_soap_tracker/features/sales/page/sales_page.dart';
import 'package:liquid_soap_tracker/features/settings/page/settings_page.dart';
import 'package:liquid_soap_tracker/features/shipment/page/shipment_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isMenuOpen = false;
  ProviderSubscription<String?>? _notificationTargetSubscription;

  @override
  void initState() {
    super.initState();
    _notificationTargetSubscription = ref.listenManual<String?>(
      notificationTargetProvider,
      (previous, next) {
        if (next == null || !mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _openNotificationTarget(next);
          ref.read(notificationTargetProvider.notifier).state = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _notificationTargetSubscription?.close();
    super.dispose();
  }

  Future<void> _openSideMenu() async {
    if (_isMenuOpen) {
      return;
    }

    _isMenuOpen = true;
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Menu',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.82,
            child: TrackerDrawer(
              profile: widget.profile,
              onOpenLoanRecords: () => _pushFromMenu(
                LoanRecordsPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenExpenses: () => _pushFromMenu(
                ExpensesPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenInventoryAdjustment: () => _pushFromMenu(
                InventoryAdjustmentPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenReceive: () => _pushFromMenu(
                ReceivePage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenShipment: () => _pushFromMenu(
                ShipmentPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenPartners: () => _pushFromMenu(
                PartnersPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenEmployees: () => _pushFromMenu(
                EmployeesPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenReports: () => _pushFromMenu(
                ReportsPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenProfile: () => _pushFromMenu(
                ProfilePage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
              onOpenSettings: () => _pushFromMenu(
                SettingsPage(
                  profile: widget.profile,
                  onMenuPressed: _openSideMenu,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
    _isMenuOpen = false;
  }

  void _goToTab(int index) {
    if (ref.read(selectedShellTabProvider) == index) {
      return;
    }
    ref.read(selectedShellTabProvider.notifier).state = index;
  }

  Future<void> _openNotificationTarget(String target) async {
    switch (target) {
      case 'loan_records':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoanRecordsPage(
              profile: widget.profile,
              onMenuPressed: _openSideMenu,
            ),
          ),
        );
        return;
      case 'shipment':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShipmentPage(
              profile: widget.profile,
              onMenuPressed: _openSideMenu,
            ),
          ),
        );
        return;
      case 'receive':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReceivePage(
              profile: widget.profile,
              onMenuPressed: _openSideMenu,
            ),
          ),
        );
        return;
      case 'sales':
        _goToTab(1);
        return;
      case 'purchased':
        _goToTab(2);
        return;
      case 'inventory':
        _goToTab(3);
        return;
      case 'account':
        _goToTab(4);
        return;
      default:
        _goToTab(0);
        return;
    }
  }

  Future<void> _pushFromMenu(Widget page) async {
    Navigator.of(context, rootNavigator: true).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => page));
  }

  List<Widget> _buildPages() {
    return [
      DashboardPage(
        profile: widget.profile,
        onMenuPressed: _openSideMenu,
        onOpenSales: () => _goToTab(1),
        onOpenPurchased: () => _goToTab(2),
        onOpenInventory: () => _goToTab(3),
        onOpenAccounts: () => _goToTab(4),
      ),
      SalesPage(profile: widget.profile, onMenuPressed: _openSideMenu),
      PurchasedPage(profile: widget.profile, onMenuPressed: _openSideMenu),
      InventoryPage(profile: widget.profile, onMenuPressed: _openSideMenu),
      AccountPage(profile: widget.profile, onMenuPressed: _openSideMenu),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedShellTabProvider);
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: const TrackerBottomNavigation(),
          ),
        ),
      ),
    );
  }
}
