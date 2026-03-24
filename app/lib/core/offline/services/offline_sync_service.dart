import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:liquid_soap_tracker/core/offline/services/connectivity_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/repositories/finance_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/product_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/production_repository.dart';
import 'package:liquid_soap_tracker/core/repositories/sales_repository.dart';

final pendingSyncCountProvider = StateProvider<int>((ref) => 0);

class OfflineSyncService {
  OfflineSyncService({
    required this.ref,
    required this.connectivityService,
    required this.localStoreService,
    required this.productRepository,
    required this.productionRepository,
    required this.salesRepository,
    required this.financeRepository,
  });

  final Ref ref;
  final ConnectivityService connectivityService;
  final LocalStoreService localStoreService;
  final ProductRepository productRepository;
  final ProductionRepository productionRepository;
  final SalesRepository salesRepository;
  final FinanceRepository financeRepository;

  Future<void> refreshPendingCount() async {
    ref.read(pendingSyncCountProvider.notifier).state = await localStoreService
        .pendingQueueCount();
  }

  Future<SyncWriteResult> enqueue({
    required OfflineSyncActionType type,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineSyncAction(
      id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await localStoreService.enqueue(action);
    await refreshPendingCount();
    return const SyncWriteResult.queued();
  }

  Future<int> syncPendingActions() async {
    if (!await connectivityService.isOnline) {
      await refreshPendingCount();
      return 0;
    }

    final pending = await localStoreService.readQueue();
    if (pending.isEmpty) {
      await localStoreService.setLastSyncAt(DateTime.now());
      await refreshPendingCount();
      return 0;
    }

    final dispatchIdMap = <String, String>{};
    final financeIdMap = <String, String>{};
    final remaining = <OfflineSyncAction>[];
    var syncedCount = 0;

    for (final action in pending) {
      try {
        switch (action.type) {
          case OfflineSyncActionType.saveProductSetup:
            final sizes = ((action.payload['sizes'] as List?) ?? const [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            await productRepository.saveSetupOnline(
              productName:
                  action.payload['product_name'] as String? ?? 'Liquid Soap',
              defaultCostPerLiter:
                  (action.payload['default_cost_per_liter'] as num?)
                      ?.toDouble() ??
                  0,
              sizesPayload: sizes,
              productImagePath: action.payload['product_image_path'] as String?,
            );
            break;
          case OfflineSyncActionType.createProductionEntry:
            await productionRepository.createEntryOnline(
              producedOn: DateTime.parse(
                action.payload['produced_on'] as String,
              ),
              sizeId: action.payload['size_id'] as String,
              quantityUnits: action.payload['quantity_units'] as int,
              notes: action.payload['notes'] as String?,
              createdBy: action.payload['created_by'] as String,
            );
            break;
          case OfflineSyncActionType.createSaleDispatch:
            final remoteDispatchId = await salesRepository.createDispatchOnline(
              userId: action.payload['user_id'] as String,
              sizePayload: Map<String, dynamic>.from(
                action.payload['size'] as Map,
              ),
              quantityUnits: action.payload['quantity_units'] as int,
              customerName: action.payload['customer_name'] as String,
              customerPhone: action.payload['customer_phone'] as String?,
              notes: action.payload['notes'] as String?,
            );
            dispatchIdMap[action.payload['local_dispatch_id'] as String] =
                remoteDispatchId;
            break;
          case OfflineSyncActionType.createSaleWithFinance:
            final result = await salesRepository
                .createDispatchWithFinanceOnline(
                  userId: action.payload['user_id'] as String,
                  sizePayload: Map<String, dynamic>.from(
                    action.payload['size'] as Map,
                  ),
                  quantityUnits: action.payload['quantity_units'] as int,
                  customerName: action.payload['customer_name'] as String,
                  customerPhone: action.payload['customer_phone'] as String?,
                  notes: action.payload['notes'] as String?,
                  unitPrice:
                      (action.payload['unit_price'] as num?)?.toDouble() ?? 0,
                  defaultCostPerLiter:
                      (action.payload['default_cost_per_liter'] as num?)
                          ?.toDouble() ??
                      0,
                  initialPaid:
                      (action.payload['initial_paid'] as num?)?.toDouble() ?? 0,
                  loanLabel: action.payload['loan_label'] as String?,
                );
            dispatchIdMap[action.payload['local_dispatch_id'] as String] =
                result.dispatchId;
            if ((action.payload['local_finance_id'] as String?) != null &&
                result.financeId != null) {
              financeIdMap[action.payload['local_finance_id'] as String] =
                  result.financeId!;
            }
            break;
          case OfflineSyncActionType.attachFinance:
            final rawDispatchId = action.payload['dispatch_id'] as String;
            final remoteDispatchId =
                dispatchIdMap[rawDispatchId] ?? rawDispatchId;
            final financeId = await financeRepository.attachFinanceOnline(
              dispatchId: remoteDispatchId,
              quantityUnits: action.payload['quantity_units'] as int,
              sizeLiters:
                  (action.payload['size_liters'] as num?)?.toDouble() ?? 0,
              unitPrice:
                  (action.payload['unit_price'] as num?)?.toDouble() ?? 0,
              defaultCostPerLiter:
                  (action.payload['default_cost_per_liter'] as num?)
                      ?.toDouble() ??
                  0,
              initialPaid:
                  (action.payload['initial_paid'] as num?)?.toDouble() ?? 0,
              loanLabel: action.payload['loan_label'] as String?,
            );
            financeIdMap[action.payload['local_finance_id'] as String] =
                financeId;
            break;
          case OfflineSyncActionType.recordPayment:
            final rawFinanceId = action.payload['sale_finance_id'] as String;
            final remoteFinanceId = financeIdMap[rawFinanceId] ?? rawFinanceId;
            await financeRepository.recordPaymentOnline(
              saleFinanceId: remoteFinanceId,
              amount: (action.payload['amount'] as num?)?.toDouble() ?? 0,
              note: action.payload['note'] as String?,
            );
            break;
          case OfflineSyncActionType.createExpenseEntry:
            await financeRepository.createExpenseOnline(
              createdBy: action.payload['created_by'] as String,
              category: action.payload['category'] as String? ?? 'Expense',
              amount: (action.payload['amount'] as num?)?.toDouble() ?? 0,
              note: action.payload['note'] as String?,
              expenseDate: DateTime.parse(
                action.payload['expense_date'] as String,
              ),
            );
            break;
        }
        syncedCount += 1;
      } catch (_) {
        remaining.add(action);
      }
    }

    await localStoreService.writeQueue(remaining);
    if (remaining.isEmpty) {
      await localStoreService.setLastSyncAt(DateTime.now());
    }
    await refreshPendingCount();
    return syncedCount;
  }
}
