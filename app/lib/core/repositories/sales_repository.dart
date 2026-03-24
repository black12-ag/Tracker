import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/sales/models/customer_model.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DispatchSyncResult {
  const DispatchSyncResult({required this.dispatchId, this.financeId});

  final String dispatchId;
  final String? financeId;
}

class SalesRepository {
  SalesRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  SalesDispatchModel _sanitizeDispatchForRole(
    SalesDispatchModel item, {
    required bool owner,
  }) {
    if (owner) {
      return item;
    }

    return SalesDispatchModel(
      id: item.id,
      customer: item.customer,
      sizeId: item.sizeId,
      sizeLabel: item.sizeLabel,
      sizeLiters: item.sizeLiters,
      quantityUnits: item.quantityUnits,
      soldAt: item.soldAt,
      dispatchStatus: item.dispatchStatus,
      notes: item.notes,
    );
  }

  Future<List<CustomerModel>> fetchCustomers() async {
    try {
      final rows = await _client.from('customers').select().order('name');
      final customers = rows
          .map<CustomerModel>(
            (row) => CustomerModel(
              id: row['id'] as String,
              name: row['name'] as String? ?? '',
              phone: row['phone'] as String?,
            ),
          )
          .toList();
      await _cacheCustomers(customers);
      return customers;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readList(
        LocalStoreService.customersKey,
      );
      return cached.map(CustomerModel.fromMap).toList();
    }
  }

  Future<int> fetchTotalSoldOn(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final rows = await _client
          .from('sales_dispatches')
          .select('quantity_units')
          .gte('sold_at', start.toIso8601String())
          .lt('sold_at', end.toIso8601String());

      return rows.fold<int>(
        0,
        (sum, row) => sum + (row['quantity_units'] as int? ?? 0),
      );
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readList(
        LocalStoreService.salesDispatchesKey(false),
      );
      return cached
          .map(SalesDispatchModel.fromMap)
          .where(
            (entry) =>
                entry.soldAt.year == date.year &&
                entry.soldAt.month == date.month &&
                entry.soldAt.day == date.day,
          )
          .fold<int>(0, (sum, entry) => sum + entry.quantityUnits);
    }
  }

  Future<List<SalesDispatchModel>> fetchRecentDispatches({
    required bool owner,
    int limit = 12,
  }) async {
    try {
      final rows = await _client
          .from('sales_dispatches')
          .select(
            'id, quantity_units, sold_at, dispatch_status, notes, customers!inner(id, name, phone), product_sizes!inner(id, label, liters)',
          )
          .order('sold_at', ascending: false)
          .limit(limit);

      final financeByDispatch = <String, Map<String, dynamic>>{};
      if (owner) {
        final financeRows = await _client
            .from('sale_finance')
            .select(
              'dispatch_id, finance_status, total_amount, balance_amount',
            );
        for (final financeRow in financeRows) {
          financeByDispatch[financeRow['dispatch_id'] as String] = financeRow;
        }
      }

      final items = rows.map<SalesDispatchModel>((row) {
        final finance = financeByDispatch[row['id'] as String];
        return SalesDispatchModel(
          id: row['id'] as String,
          customer: CustomerModel(
            id: row['customers']['id'] as String,
            name: row['customers']['name'] as String? ?? '',
            phone: row['customers']['phone'] as String?,
          ),
          sizeId: row['product_sizes']['id'] as String,
          sizeLabel: row['product_sizes']['label'] as String? ?? '',
          sizeLiters: _asDouble(row['product_sizes']['liters']),
          quantityUnits: row['quantity_units'] as int? ?? 0,
          soldAt: DateTime.parse(row['sold_at'] as String),
          dispatchStatus: row['dispatch_status'] as String? ?? 'recorded',
          notes: row['notes'] as String?,
          financeStatus: finance?['finance_status'] as String?,
          totalAmount: (finance?['total_amount'] as num?)?.toDouble(),
          balanceAmount: (finance?['balance_amount'] as num?)?.toDouble(),
        );
      }).toList();

      await _cacheDispatches(owner, items);
      return items;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readList(
        LocalStoreService.salesDispatchesKey(owner),
      );
      return cached
          .map(SalesDispatchModel.fromMap)
          .map((item) => _sanitizeDispatchForRole(item, owner: owner))
          .take(limit)
          .toList();
    }
  }

  Future<String> createDispatchOnline({
    required String userId,
    required Map<String, dynamic> sizePayload,
    required int quantityUnits,
    required String customerName,
    required String? customerPhone,
    required String? notes,
  }) async {
    final customerId = await _resolveCustomerId(
      name: customerName.trim(),
      phone: customerPhone?.trim(),
    );

    final dispatch = await _client
        .from('sales_dispatches')
        .insert({
          'customer_id': customerId,
          'size_id': sizePayload['id'],
          'quantity_units': quantityUnits,
          'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
          'created_by': userId,
        })
        .select()
        .single();
    return dispatch['id'] as String;
  }

  Future<DispatchSyncResult> createDispatchWithFinanceOnline({
    required String userId,
    required Map<String, dynamic> sizePayload,
    required int quantityUnits,
    required String customerName,
    required String? customerPhone,
    required String? notes,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    final dispatchId = await createDispatchOnline(
      userId: userId,
      sizePayload: sizePayload,
      quantityUnits: quantityUnits,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );

    final financeId = await _attachFinanceOnline(
      dispatchId: dispatchId,
      quantityUnits: quantityUnits,
      sizeLiters: (sizePayload['liters'] as num?)?.toDouble() ?? 0,
      unitPrice: unitPrice,
      defaultCostPerLiter: defaultCostPerLiter,
      initialPaid: initialPaid,
      loanLabel: loanLabel,
    );

    return DispatchSyncResult(dispatchId: dispatchId, financeId: financeId);
  }

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
    try {
      if (owner && unitPrice != null && defaultCostPerLiter != null) {
        await createDispatchWithFinanceOnline(
          userId: userId,
          sizePayload: size.toMap(),
          quantityUnits: quantityUnits,
          customerName: customerName,
          customerPhone: customerPhone,
          notes: notes,
          unitPrice: unitPrice,
          defaultCostPerLiter: defaultCostPerLiter,
          initialPaid: initialPaid,
          loanLabel: loanLabel,
        );
      } else {
        await createDispatchOnline(
          userId: userId,
          sizePayload: size.toMap(),
          quantityUnits: quantityUnits,
          customerName: customerName,
          customerPhone: customerPhone,
          notes: notes,
        );
      }
      return const SyncWriteResult.synced('Sale saved.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      final localDispatchId =
          'local-dispatch-${DateTime.now().microsecondsSinceEpoch}';
      final localFinanceId =
          'local-finance-${DateTime.now().microsecondsSinceEpoch}';
      final localCustomer = CustomerModel(
        id: 'local-customer-${DateTime.now().microsecondsSinceEpoch}',
        name: customerName.trim(),
        phone: customerPhone?.trim().isEmpty ?? true
            ? null
            : customerPhone?.trim(),
      );
      final totalAmount = owner && unitPrice != null
          ? unitPrice * quantityUnits
          : null;
      final balanceAmount = owner && unitPrice != null
          ? (totalAmount! - initialPaid).clamp(0, double.infinity).toDouble()
          : null;
      final financeStatus = owner && unitPrice != null
          ? (balanceAmount == 0
                ? 'paid'
                : initialPaid > 0
                ? 'partial'
                : 'unpaid')
          : null;

      final localDispatch = SalesDispatchModel(
        id: localDispatchId,
        customer: localCustomer,
        sizeId: size.id,
        sizeLabel: size.label,
        sizeLiters: size.liters,
        quantityUnits: quantityUnits,
        soldAt: DateTime.now(),
        dispatchStatus: 'recorded',
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        financeStatus: financeStatus,
        totalAmount: totalAmount,
        balanceAmount: balanceAmount,
      );

      await _cacheCustomers(await _mergeCustomers([localCustomer]));
      await _cacheDispatches(
        false,
        await _mergeDispatches(localDispatch, owner: false),
      );
      await _cacheDispatches(
        true,
        await _mergeDispatches(localDispatch, owner: true),
      );

      if (owner && unitPrice != null && defaultCostPerLiter != null) {
        await _cacheOfflineOwnerFinance(
          localFinanceId: localFinanceId,
          dispatch: localDispatch,
          unitPrice: unitPrice,
          defaultCostPerLiter: defaultCostPerLiter,
          initialPaid: initialPaid,
          loanLabel: loanLabel,
        );
      }

      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: owner && unitPrice != null && defaultCostPerLiter != null
              ? OfflineSyncActionType.createSaleWithFinance
              : OfflineSyncActionType.createSaleDispatch,
          payload: {
            'local_dispatch_id': localDispatchId,
            'local_finance_id': localFinanceId,
            'user_id': userId,
            'size': size.toMap(),
            'quantity_units': quantityUnits,
            'customer_name': customerName.trim(),
            'customer_phone': customerPhone?.trim().isEmpty ?? true
                ? null
                : customerPhone?.trim(),
            'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
            'unit_price': unitPrice,
            'default_cost_per_liter': defaultCostPerLiter,
            'initial_paid': initialPaid,
            'loan_label': loanLabel?.trim().isEmpty ?? true
                ? null
                : loanLabel?.trim(),
          },
          createdAt: DateTime.now(),
        ),
      );
      return const SyncWriteResult.queued();
    }
  }

  Future<String> _resolveCustomerId({
    required String name,
    required String? phone,
  }) async {
    final existing = await _client
        .from('customers')
        .select()
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      if ((phone?.isNotEmpty ?? false) && existing['phone'] != phone) {
        await _client
            .from('customers')
            .update({'phone': phone})
            .eq('id', existing['id']);
      }

      return existing['id'] as String;
    }

    final inserted = await _client
        .from('customers')
        .insert({'name': name, 'phone': phone?.isEmpty ?? true ? null : phone})
        .select()
        .single();

    return inserted['id'] as String;
  }

  Future<void> _cacheCustomers(List<CustomerModel> customers) async {
    await _localStoreService.writeList(
      LocalStoreService.customersKey,
      customers.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<CustomerModel>> _mergeCustomers(
    List<CustomerModel> additions,
  ) async {
    final existing = (await _localStoreService.readList(
      LocalStoreService.customersKey,
    )).map(CustomerModel.fromMap).toList();
    final byName = <String, CustomerModel>{
      for (final customer in existing) customer.name.toLowerCase(): customer,
    };
    for (final customer in additions) {
      byName[customer.name.toLowerCase()] = customer;
    }
    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return merged;
  }

  Future<void> _cacheDispatches(
    bool owner,
    List<SalesDispatchModel> items,
  ) async {
    await _localStoreService.writeList(
      LocalStoreService.salesDispatchesKey(owner),
      items
          .map((item) => _sanitizeDispatchForRole(item, owner: owner))
          .map((item) => item.toMap())
          .toList(),
    );
  }

  Future<List<SalesDispatchModel>> _mergeDispatches(
    SalesDispatchModel entry, {
    required bool owner,
  }) async {
    final existing =
        (await _localStoreService.readList(
              LocalStoreService.salesDispatchesKey(owner),
            ))
            .map(SalesDispatchModel.fromMap)
            .where((item) => item.id != entry.id)
            .toList();
    return [
      _sanitizeDispatchForRole(entry, owner: owner),
      ...existing.map((item) => _sanitizeDispatchForRole(item, owner: owner)),
    ]..sort((a, b) => b.soldAt.compareTo(a.soldAt));
  }

  Future<void> _cacheOfflineOwnerFinance({
    required String localFinanceId,
    required SalesDispatchModel dispatch,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    final totalAmount = unitPrice * dispatch.quantityUnits;
    final paidAmount = initialPaid;
    final balanceAmount = (totalAmount - paidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final unitCost = dispatch.sizeLiters * defaultCostPerLiter;
    final record = FinanceRecord(
      id: localFinanceId,
      dispatchId: dispatch.id,
      customerName: dispatch.customer.name,
      sizeLabel: dispatch.sizeLabel,
      sizeLiters: dispatch.sizeLiters,
      quantityUnits: dispatch.quantityUnits,
      soldAt: dispatch.soldAt,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balanceAmount: balanceAmount,
      unitPriceSnapshot: unitPrice,
      unitCostSnapshot: unitCost,
      financeStatus: balanceAmount == 0
          ? 'paid'
          : paidAmount > 0
          ? 'partial'
          : 'unpaid',
      loanLabel: balanceAmount > 0
          ? (loanLabel?.trim().isEmpty ?? true
                ? 'Customer loan'
                : loanLabel?.trim())
          : null,
    );

    final existingRecords =
        (await _localStoreService.readList(LocalStoreService.financeRecordsKey))
            .map(FinanceRecord.fromMap)
            .where((item) => item.dispatchId != dispatch.id)
            .toList();
    final mergedRecords = [record, ...existingRecords]
      ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
    await _localStoreService.writeList(
      LocalStoreService.financeRecordsKey,
      mergedRecords.map((item) => item.toMap()).toList(),
    );

    final existingSummaryMap = await _localStoreService.readMap(
      LocalStoreService.financeSummaryKey,
    );
    final existingSummary = existingSummaryMap == null
        ? const FinanceSummary.empty()
        : FinanceSummary.fromMap(existingSummaryMap);

    final nextSummary = FinanceSummary(
      totalSales: existingSummary.totalSales + totalAmount,
      totalPaid: existingSummary.totalPaid + paidAmount,
      totalBalance: existingSummary.totalBalance + balanceAmount,
      estimatedProfit:
          existingSummary.estimatedProfit +
          ((unitPrice - unitCost) * dispatch.quantityUnits),
      totalExpenses: existingSummary.totalExpenses,
      netProfit:
          existingSummary.netProfit +
          ((unitPrice - unitCost) * dispatch.quantityUnits),
      openLoans: existingSummary.openLoans + (balanceAmount > 0 ? 1 : 0),
    );

    await _localStoreService.writeMap(
      LocalStoreService.financeSummaryKey,
      nextSummary.toMap(),
    );
  }

  Future<String> _attachFinanceOnline({
    required String dispatchId,
    required int quantityUnits,
    required double sizeLiters,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    final unitCost = sizeLiters * defaultCostPerLiter;
    final totalAmount = unitPrice * quantityUnits;
    final finance = await _client
        .from('sale_finance')
        .insert({
          'dispatch_id': dispatchId,
          'unit_price_snapshot': unitPrice,
          'unit_cost_snapshot': unitCost,
          'total_amount': totalAmount,
          'loan_label': totalAmount - initialPaid > 0
              ? (loanLabel?.trim().isEmpty ?? true
                    ? 'Customer loan'
                    : loanLabel?.trim())
              : null,
        })
        .select()
        .single();

    if (initialPaid > 0) {
      await _client.from('payment_records').insert({
        'sale_finance_id': finance['id'],
        'amount': initialPaid,
        'payment_date': DateTime.now().toIso8601String().split('T').first,
        'note': 'Initial payment',
      });
    }

    return finance['id'] as String;
  }
}
