import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_soap_tracker/app/shell/app_shell.dart';
import 'package:liquid_soap_tracker/app/theme/app_theme.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/services/connectivity_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/repositories/auth_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/finance_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/product_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/production_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/sales_repository.dart';
import 'package:liquid_soap_tracker/features/auth/widgets/buttons/login_submit_button.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/dashboard/models/dashboard_bundle.dart';
import 'package:liquid_soap_tracker/features/finance/controller/finance_controller.dart';
import 'package:liquid_soap_tracker/features/finance/models/expense_entry.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';
import 'package:liquid_soap_tracker/features/finance/page/finance_page.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/product_setup/page/product_setup_page.dart';
import 'package:liquid_soap_tracker/features/production/controller/production_controller.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';
import 'package:liquid_soap_tracker/features/production/page/production_page.dart';
import 'package:liquid_soap_tracker/features/sales/controller/sales_controller.dart';
import 'package:liquid_soap_tracker/features/sales/models/customer_model.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';
import 'package:liquid_soap_tracker/features/sales/page/sales_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _dummyClient() => SupabaseClient(
  'https://example.supabase.co',
  'test-anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

const ownerProfile = AppProfile(
  id: 'owner-id',
  email: 'owner@fesajtracker.com',
  displayName: 'Owner',
  role: UserRole.owner,
  isActive: true,
);

const operatorProfile = AppProfile(
  id: 'operator-id',
  email: 'operator@fesajtracker.com',
  displayName: 'Operator',
  role: UserRole.operator,
  isActive: true,
);

const productBundle = ProductSetupBundle(
  productName: 'Liquid Soap',
  defaultCostPerLiter: 10,
  canSeeFinancials: true,
  sizes: [
    ProductSizeSetting(
      id: 'size-1',
      label: '1L',
      liters: 1,
      lowStockThreshold: 5,
      active: true,
      unitPrice: 25,
      currentStockUnits: 8,
    ),
    ProductSizeSetting(
      id: 'size-2',
      label: '2.5L',
      liters: 2.5,
      lowStockThreshold: 4,
      active: true,
      unitPrice: 55,
      currentStockUnits: 6,
    ),
  ],
);

final productionEntries = [
  ProductionEntryModel(
    id: 'prod-1',
    producedOn: DateTime(2026, 3, 24),
    quantityUnits: 4,
    sizeLabel: '1L',
    sizeLiters: 1,
  ),
];

final salesDispatches = [
  SalesDispatchModel(
    id: 'dispatch-1',
    customer: CustomerModel(id: 'customer-1', name: 'Shop A', phone: '0900'),
    sizeId: 'size-1',
    sizeLabel: '1L',
    sizeLiters: 1,
    quantityUnits: 2,
    soldAt: DateTime(2026, 3, 24, 9),
    dispatchStatus: 'recorded',
    financeStatus: 'partial',
    totalAmount: 50,
    balanceAmount: 20,
  ),
];

const financeSummary = FinanceSummary(
  totalSales: 500,
  totalPaid: 350,
  totalBalance: 150,
  estimatedProfit: 180,
  totalExpenses: 40,
  netProfit: 140,
  openLoans: 2,
);

final financeRecords = [
  FinanceRecord(
    id: 'finance-1',
    dispatchId: 'dispatch-1',
    customerName: 'Shop A',
    sizeLabel: '1L',
    sizeLiters: 1,
    quantityUnits: 2,
    soldAt: DateTime(2026, 3, 24, 9),
    totalAmount: 50,
    paidAmount: 30,
    balanceAmount: 20,
    unitPriceSnapshot: 25,
    unitCostSnapshot: 10,
    financeStatus: 'partial',
    loanLabel: 'Customer loan',
  ),
];

final expenseEntries = [
  ExpenseEntry(
    id: 'expense-1',
    expenseDate: DateTime(2026, 3, 24),
    category: 'Packaging',
    amount: 40,
    note: 'Bottles and labels',
  ),
];

final dashboardBundle = DashboardBundle(
  productName: 'Liquid Soap',
  inventory: productBundle.sizes,
  todayProductionUnits: 4,
  todaySalesUnits: 2,
  recentProduction: productionEntries,
  recentSales: salesDispatches,
  financeSummary: financeSummary,
);

class FakeConnectivityService extends ConnectivityService {
  @override
  Stream<bool> get onStatusChanged => Stream<bool>.value(true);

  @override
  Future<bool> get isOnline async => true;
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(_dummyClient(), LocalStoreService());

  int signOutCalls = 0;

  @override
  Stream<AuthState> get authStateChanges => Stream<AuthState>.empty();

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class FakeProductRepository extends ProductRepository {
  FakeProductRepository() : super(_dummyClient(), LocalStoreService());

  int saveCalls = 0;

  @override
  Future<ProductSetupBundle> fetchBundle({required bool owner}) async =>
      productBundle;

  @override
  Future<SyncWriteResult> saveSetup({
    required String productName,
    required double defaultCostPerLiter,
    required List<ProductSizeSetting> sizes,
    String? productImagePath,
    String? productImageUrl,
  }) async {
    saveCalls += 1;
    return const SyncWriteResult.synced();
  }
}

class FakeProductionRepository extends ProductionRepository {
  FakeProductionRepository() : super(_dummyClient(), LocalStoreService());

  int createCalls = 0;

  @override
  Future<List<ProductionEntryModel>> fetchRecentEntries({
    int limit = 8,
  }) async => productionEntries;

  @override
  Future<int> fetchTotalProducedOn(DateTime date) async => 4;

  @override
  Future<SyncWriteResult> createEntry({
    required DateTime producedOn,
    required String sizeId,
    required int quantityUnits,
    required String? notes,
    required String createdBy,
    required String sizeLabel,
    required double sizeLiters,
  }) async {
    createCalls += 1;
    return const SyncWriteResult.synced();
  }
}

class FakeSalesRepository extends SalesRepository {
  FakeSalesRepository() : super(_dummyClient(), LocalStoreService());

  int createCalls = 0;

  @override
  Future<List<CustomerModel>> fetchCustomers() async => const [
    CustomerModel(id: 'customer-1', name: 'Shop A', phone: '0900'),
  ];

  @override
  Future<int> fetchTotalSoldOn(DateTime date) async => 2;

  @override
  Future<List<SalesDispatchModel>> fetchRecentDispatches({
    required bool owner,
    int limit = 12,
  }) async => salesDispatches;

  @override
  Future<SyncWriteResult> createDispatch({
    required String userId,
    required ProductSizeSetting size,
    required int quantityUnits,
    required String customerName,
    required String? customerPhone,
    required String? notes,
    required bool owner,
    double? unitPrice,
    double? defaultCostPerLiter,
    double initialPaid = 0,
    String? loanLabel,
  }) async {
    createCalls += 1;
    return const SyncWriteResult.synced();
  }
}

class FakeFinanceRepository extends FinanceRepository {
  FakeFinanceRepository() : super(_dummyClient(), LocalStoreService());

  int attachCalls = 0;
  int paymentCalls = 0;

  @override
  Future<FinanceSummary> fetchSummary() async => financeSummary;

  @override
  Future<List<FinanceRecord>> fetchFinanceRecords({int limit = 20}) async =>
      financeRecords;

  @override
  Future<List<ExpenseEntry>> fetchExpenses({int limit = 20}) async =>
      expenseEntries;

  @override
  Future<List<SalesDispatchModel>> fetchPendingFinanceDispatches() async =>
      salesDispatches;

  @override
  Future<SyncWriteResult> attachFinance({
    required SalesDispatchModel dispatch,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    attachCalls += 1;
    return const SyncWriteResult.synced();
  }

  @override
  Future<SyncWriteResult> recordPayment({
    required String saleFinanceId,
    required double amount,
    String? note,
  }) async {
    paymentCalls += 1;
    return const SyncWriteResult.synced();
  }
}

Widget _wrapWithProviders({
  required Widget child,
  required AppProfile profile,
  bool wrapInScaffold = true,
  FakeAuthRepository? authRepository,
  FakeProductRepository? productRepository,
  FakeProductionRepository? productionRepository,
  FakeSalesRepository? salesRepository,
  FakeFinanceRepository? financeRepository,
}) {
  final authRepo = authRepository ?? FakeAuthRepository();
  final productRepo = productRepository ?? FakeProductRepository();
  final productionRepo = productionRepository ?? FakeProductionRepository();
  final salesRepo = salesRepository ?? FakeSalesRepository();
  final financeRepo = financeRepository ?? FakeFinanceRepository();

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      productionRepositoryProvider.overrideWithValue(productionRepo),
      salesRepositoryProvider.overrideWithValue(salesRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
      localStoreServiceProvider.overrideWithValue(LocalStoreService()),
      currentProfileProvider.overrideWith((ref) async => profile),
      dashboardBundleProvider.overrideWith((ref) async => dashboardBundle),
      productSetupBundleProvider.overrideWith((ref) async => productBundle),
      productionEntriesProvider.overrideWith((ref) async => productionEntries),
      salesDispatchesProvider.overrideWith((ref) async => salesDispatches),
      salesCustomersProvider.overrideWith(
        (ref) async => const [
          CustomerModel(id: 'customer-1', name: 'Shop A', phone: '0900'),
        ],
      ),
      financeSummaryProvider.overrideWith((ref) async => financeSummary),
      financeRecordsProvider.overrideWith((ref) async => financeRecords),
      expenseEntriesProvider.overrideWith((ref) async => expenseEntries),
      pendingFinanceDispatchesProvider.overrideWith(
        (ref) async => salesDispatches,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: wrapInScaffold ? Scaffold(body: child) : child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(const {});
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> scrollToText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login button is clickable', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginSubmitButton(onPressed: () => tapped += 1, isBusy: false),
        ),
      ),
    );

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(tapped, 1);
  });

  test('owner phone aliases normalize to the owner email', () {
    expect(
      AppIdentity.normalizeLoginIdentifier('092 2380260'),
      AppIdentity.ownerCanonicalEmail,
    );
    expect(
      AppIdentity.normalizeLoginIdentifier('+251922380260'),
      AppIdentity.ownerCanonicalEmail,
    );
    expect(
      AppIdentity.normalizeLoginIdentifier('MUAY01111@GMAIL.COM'),
      'muay01111@gmail.com',
    );
  });

  testWidgets('owner shell shows finance tab and logout works', (tester) async {
    final authRepo = FakeAuthRepository();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AppShell(profile: ownerProfile),
        profile: ownerProfile,
        wrapInScaffold: false,
        authRepository: authRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Sizes'), findsOneWidget);

    await tester.tap(find.text('Sizes'));
    await tester.pumpAndSettle();
    expect(find.text('Product'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(authRepo.signOutCalls, 1);
  });

  testWidgets('operator shell hides finance tab', (tester) async {
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AppShell(profile: operatorProfile),
        profile: operatorProfile,
        wrapInScaffold: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Money'), findsNothing);
  });

  testWidgets('product setup save button calls repository', (tester) async {
    final productRepo = FakeProductRepository();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const ProductSetupPage(profile: ownerProfile),
        profile: ownerProfile,
        productRepository: productRepo,
      ),
    );
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Save Product');
    await tester.tap(find.text('Save Product'));
    await tester.pumpAndSettle();

    expect(productRepo.saveCalls, 1);
  });

  testWidgets('production save button calls repository', (tester) async {
    final productionRepo = FakeProductionRepository();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const ProductionPage(profile: ownerProfile),
        profile: ownerProfile,
        productionRepository: productionRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '3');
    await scrollToText(tester, 'Add Production');
    await tester.tap(find.text('Add Production'));
    await tester.pumpAndSettle();

    expect(productionRepo.createCalls, 1);
  });

  testWidgets('owner sales save button calls repository', (tester) async {
    final salesRepo = FakeSalesRepository();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const SalesPage(profile: ownerProfile),
        profile: ownerProfile,
        salesRepository: salesRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Shop B');
    await tester.enterText(find.byType(TextFormField).at(2), '2');
    await tester.enterText(find.byType(TextFormField).at(4), '25');
    await scrollToText(tester, 'Save Sale');
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();

    expect(salesRepo.createCalls, 1);
  });

  testWidgets('finance actions call repository', (tester) async {
    final financeRepo = FakeFinanceRepository();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const FinancePage(profile: ownerProfile),
        profile: ownerProfile,
        financeRepository: financeRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '25');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await scrollToText(tester, 'Add Money To Sale');
    await tester.tap(find.text('Add Money To Sale'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(3), '4');
    await scrollToText(tester, 'Add Payment');
    await tester.tap(find.text('Add Payment'));
    await tester.pumpAndSettle();

    expect(financeRepo.attachCalls, 1);
    expect(financeRepo.paymentCalls, 1);
  });
}
