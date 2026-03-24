import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/offline/services/connectivity_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_sync_service.dart';
import 'package:liquid_soap_tracker/core/repositories/auth_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/finance_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/product_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/production_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/sales_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final localStoreServiceProvider = Provider<LocalStoreService>(
  (ref) => LocalStoreService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
  ),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
  ),
);

final productionRepositoryProvider = Provider<ProductionRepository>(
  (ref) => ProductionRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
  ),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
  ),
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
  ),
);

final offlineSyncServiceProvider = Provider<OfflineSyncService>(
  (ref) => OfflineSyncService(
    ref: ref,
    connectivityService: ref.watch(connectivityServiceProvider),
    localStoreService: ref.watch(localStoreServiceProvider),
    productRepository: ref.watch(productRepositoryProvider),
    productionRepository: ref.watch(productionRepositoryProvider),
    salesRepository: ref.watch(salesRepositoryProvider),
    financeRepository: ref.watch(financeRepositoryProvider),
  ),
);

final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChanged,
);

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

final currentProfileProvider = FutureProvider<AppProfile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return null;
  }

  return ref.watch(authRepositoryProvider).fetchProfile();
});
