import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/finance/controller/finance_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/production/controller/production_controller.dart';
import 'package:liquid_soap_tracker/features/sales/controller/sales_controller.dart';

class AppSyncBootstrap extends ConsumerStatefulWidget {
  const AppSyncBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppSyncBootstrap> createState() => _AppSyncBootstrapState();
}

class _AppSyncBootstrapState extends ConsumerState<AppSyncBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> _syncAndRefresh() async {
    await ref.read(offlineSyncServiceProvider).refreshPendingCount();
    await ref.read(offlineSyncServiceProvider).syncPendingActions();
    _refreshAppData();
  }

  void _refreshAppData() {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(dashboardBundleProvider);
    ref.invalidate(productSetupBundleProvider);
    ref.invalidate(productionEntriesProvider);
    ref.invalidate(salesDispatchesProvider);
    ref.invalidate(salesCustomersProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(financeRecordsProvider);
    ref.invalidate(expenseEntriesProvider);
    ref.invalidate(pendingFinanceDispatchesProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() async {
      await _syncAndRefresh();
    });

    _connectivitySubscription = ref
        .read(connectivityServiceProvider)
        .onStatusChanged
        .listen((isOnline) async {
          if (isOnline) {
            await _syncAndRefresh();
          }
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncAndRefresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
