import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/features/finance/models/expense_entry.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';
import 'package:liquid_soap_tracker/features/sales/models/customer_model.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  FinanceRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  Future<FinanceSummary> fetchSummary() async {
    try {
      final rows = await _client.rpc('owner_finance_summary');
      if (rows is! List || rows.isEmpty) {
        return const FinanceSummary.empty();
      }

      final row = rows.first as Map<String, dynamic>;
      final summary = FinanceSummary(
        totalSales: _asDouble(row['total_sales']),
        totalPaid: _asDouble(row['total_paid']),
        totalBalance: _asDouble(row['total_balance']),
        estimatedProfit: _asDouble(row['estimated_profit']),
        totalExpenses: _asDouble(row['total_expenses']),
        netProfit: _asDouble(row['net_profit']),
        openLoans: row['open_loans'] as int? ?? 0,
      );
      await _localStoreService.writeMap(
        LocalStoreService.financeSummaryKey,
        summary.toMap(),
      );
      return summary;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readMap(
        LocalStoreService.financeSummaryKey,
      );
      return cached == null
          ? const FinanceSummary.empty()
          : FinanceSummary.fromMap(cached);
    }
  }

  Future<List<FinanceRecord>> fetchFinanceRecords({int limit = 20}) async {
    try {
      final financeRows = await _client
          .from('sale_finance')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (financeRows.isEmpty) {
        return const [];
      }

      final dispatchIds = financeRows
          .map<String>((row) => row['dispatch_id'] as String)
          .toList();

      final dispatchRows = await _client
          .from('sales_dispatches')
          .select(
            'id, quantity_units, sold_at, customers!inner(name), product_sizes!inner(label, liters)',
          )
          .inFilter('id', dispatchIds);

      final dispatchById = <String, Map<String, dynamic>>{
        for (final row in dispatchRows) row['id'] as String: row,
      };

      final records = financeRows.map<FinanceRecord>((row) {
        final dispatch = dispatchById[row['dispatch_id'] as String] ?? {};
        final productSize =
            dispatch['product_sizes'] as Map<String, dynamic>? ?? {};
        final customer = dispatch['customers'] as Map<String, dynamic>? ?? {};
        return FinanceRecord(
          id: row['id'] as String,
          dispatchId: row['dispatch_id'] as String,
          customerName: customer['name'] as String? ?? 'Unknown customer',
          sizeLabel: productSize['label'] as String? ?? '',
          sizeLiters: _asDouble(productSize['liters']),
          quantityUnits: dispatch['quantity_units'] as int? ?? 0,
          soldAt:
              DateTime.tryParse(dispatch['sold_at'] as String? ?? '') ??
              DateTime.now(),
          totalAmount: _asDouble(row['total_amount']),
          paidAmount: _asDouble(row['paid_amount']),
          balanceAmount: _asDouble(row['balance_amount']),
          unitPriceSnapshot: _asDouble(row['unit_price_snapshot']),
          unitCostSnapshot: _asDouble(row['unit_cost_snapshot']),
          financeStatus: row['finance_status'] as String? ?? 'unpaid',
          loanLabel: row['loan_label'] as String?,
        );
      }).toList();

      await _localStoreService.writeList(
        LocalStoreService.financeRecordsKey,
        records.map((item) => item.toMap()).toList(),
      );
      return records;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readList(
        LocalStoreService.financeRecordsKey,
      );
      return cached.map(FinanceRecord.fromMap).take(limit).toList();
    }
  }

  Future<List<ExpenseEntry>> fetchExpenses({int limit = 20}) async {
    try {
      final rows = await _client
          .from('expense_entries')
          .select()
          .order('expense_date', ascending: false)
          .limit(limit);

      final items = rows
          .map<ExpenseEntry>(
            (row) => ExpenseEntry(
              id: row['id'] as String,
              expenseDate:
                  DateTime.tryParse(row['expense_date'] as String? ?? '') ??
                  DateTime.now(),
              category: row['category'] as String? ?? 'Expense',
              amount: _asDouble(row['amount']),
              note: row['note'] as String?,
            ),
          )
          .toList();

      await _localStoreService.writeList(
        LocalStoreService.expenseEntriesKey,
        items.map((item) => item.toMap()).toList(),
      );
      return items;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      final cached = await _localStoreService.readList(
        LocalStoreService.expenseEntriesKey,
      );
      return cached.map(ExpenseEntry.fromMap).take(limit).toList();
    }
  }

  Future<List<SalesDispatchModel>> fetchPendingFinanceDispatches() async {
    try {
      final dispatchRows = await _client
          .from('sales_dispatches')
          .select(
            'id, quantity_units, sold_at, dispatch_status, notes, customers!inner(id, name, phone), product_sizes!inner(id, label, liters)',
          )
          .order('sold_at', ascending: false)
          .limit(25);

      final dispatchIds =
          dispatchRows.map<String>((row) => row['id'] as String).toList();
      final financeRows = await _client
          .from('sale_finance')
          .select('dispatch_id')
          .inFilter('dispatch_id', dispatchIds);
      final financedDispatchIds = financeRows
          .map<String>((row) => row['dispatch_id'] as String)
          .toSet();

      return dispatchRows
          .where((row) => !financedDispatchIds.contains(row['id']))
          .map<SalesDispatchModel>(
            (row) => SalesDispatchModel(
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
            ),
          )
          .toList();
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final dispatches = (await _localStoreService.readList(
        LocalStoreService.salesDispatchesKey(true),
      )).map(SalesDispatchModel.fromMap).toList();
      final financeRecords = (await _localStoreService.readList(
        LocalStoreService.financeRecordsKey,
      )).map(FinanceRecord.fromMap).toList();
      final financedIds = financeRecords.map((item) => item.dispatchId).toSet();
      return dispatches
          .where((item) => !financedIds.contains(item.id))
          .toList();
    }
  }

  Future<String> attachFinanceOnline({
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

  Future<SyncWriteResult> attachFinance({
    required SalesDispatchModel dispatch,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    try {
      await attachFinanceOnline(
        dispatchId: dispatch.id,
        quantityUnits: dispatch.quantityUnits,
        sizeLiters: dispatch.sizeLiters,
        unitPrice: unitPrice,
        defaultCostPerLiter: defaultCostPerLiter,
        initialPaid: initialPaid,
        loanLabel: loanLabel,
      );
      return const SyncWriteResult.synced('Money added to the sale.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final localFinanceId =
          'local-finance-${DateTime.now().microsecondsSinceEpoch}';
      await _cacheFinanceOffline(
        localFinanceId: localFinanceId,
        dispatch: dispatch,
        unitPrice: unitPrice,
        defaultCostPerLiter: defaultCostPerLiter,
        initialPaid: initialPaid,
        loanLabel: loanLabel,
      );
      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: OfflineSyncActionType.attachFinance,
          payload: {
            'local_finance_id': localFinanceId,
            'dispatch_id': dispatch.id,
            'quantity_units': dispatch.quantityUnits,
            'size_liters': dispatch.sizeLiters,
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

  Future<void> recordPaymentOnline({
    required String saleFinanceId,
    required double amount,
    String? note,
  }) async {
    await _client.from('payment_records').insert({
      'sale_finance_id': saleFinanceId,
      'amount': amount,
      'payment_date': DateTime.now().toIso8601String().split('T').first,
      'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
    });
  }

  Future<void> createExpenseOnline({
    required String createdBy,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    await _client.from('expense_entries').insert({
      'category': category.trim(),
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
      'created_by': createdBy,
    });
  }

  Future<SyncWriteResult> createExpense({
    required String createdBy,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    try {
      await createExpenseOnline(
        createdBy: createdBy,
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        note: note,
      );
      return const SyncWriteResult.synced('Expense saved.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      await _cacheExpenseOffline(
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        note: note,
      );

      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: OfflineSyncActionType.createExpenseEntry,
          payload: {
            'created_by': createdBy,
            'category': category.trim(),
            'amount': amount,
            'expense_date': expenseDate.toIso8601String(),
            'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
          },
          createdAt: DateTime.now(),
        ),
      );
      return const SyncWriteResult.queued();
    }
  }

  Future<SyncWriteResult> recordPayment({
    required String saleFinanceId,
    required double amount,
    String? note,
  }) async {
    try {
      await recordPaymentOnline(
        saleFinanceId: saleFinanceId,
        amount: amount,
        note: note,
      );
      return const SyncWriteResult.synced('Payment saved.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      await _cachePaymentOffline(saleFinanceId: saleFinanceId, amount: amount);
      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: OfflineSyncActionType.recordPayment,
          payload: {
            'sale_finance_id': saleFinanceId,
            'amount': amount,
            'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
          },
          createdAt: DateTime.now(),
        ),
      );
      return const SyncWriteResult.queued();
    }
  }

  Future<void> _cacheFinanceOffline({
    required String localFinanceId,
    required SalesDispatchModel dispatch,
    required double unitPrice,
    required double defaultCostPerLiter,
    required double initialPaid,
    required String? loanLabel,
  }) async {
    final unitCost = dispatch.sizeLiters * defaultCostPerLiter;
    final totalAmount = unitPrice * dispatch.quantityUnits;
    final paidAmount = initialPaid;
    final balanceAmount = (totalAmount - paidAmount)
        .clamp(0, double.infinity)
        .toDouble();

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

    await _updateSummaryCache(
      totalSalesDelta: totalAmount,
      totalPaidDelta: paidAmount,
      totalBalanceDelta: balanceAmount,
      estimatedProfitDelta: (unitPrice - unitCost) * dispatch.quantityUnits,
      totalExpensesDelta: 0,
      openLoansDelta: balanceAmount > 0 ? 1 : 0,
    );
  }

  Future<void> _cachePaymentOffline({
    required String saleFinanceId,
    required double amount,
  }) async {
    final records = (await _localStoreService.readList(
      LocalStoreService.financeRecordsKey,
    )).map(FinanceRecord.fromMap).toList();
    final updated = records.map((item) {
      if (item.id != saleFinanceId) {
        return item;
      }
      final nextPaid = item.paidAmount + amount;
      final nextBalance = (item.balanceAmount - amount)
          .clamp(0, double.infinity)
          .toDouble();
      return FinanceRecord(
        id: item.id,
        dispatchId: item.dispatchId,
        customerName: item.customerName,
        sizeLabel: item.sizeLabel,
        sizeLiters: item.sizeLiters,
        quantityUnits: item.quantityUnits,
        soldAt: item.soldAt,
        totalAmount: item.totalAmount,
        paidAmount: nextPaid,
        balanceAmount: nextBalance,
        unitPriceSnapshot: item.unitPriceSnapshot,
        unitCostSnapshot: item.unitCostSnapshot,
        financeStatus: nextBalance == 0
            ? 'paid'
            : nextPaid > 0
            ? 'partial'
            : 'unpaid',
        loanLabel: item.loanLabel,
      );
    }).toList();

    FinanceRecord? previousRecord;
    for (final item in records) {
      if (item.id == saleFinanceId) {
        previousRecord = item;
        break;
      }
    }

    await _localStoreService.writeList(
      LocalStoreService.financeRecordsKey,
      updated.map((item) => item.toMap()).toList(),
    );

    await _updateSummaryCache(
      totalSalesDelta: 0,
      totalPaidDelta: amount,
      totalBalanceDelta: -amount,
      estimatedProfitDelta: 0,
      totalExpensesDelta: 0,
      openLoansDelta:
          previousRecord != null &&
              previousRecord.balanceAmount > 0 &&
              (previousRecord.balanceAmount - amount) <= 0
          ? -1
          : 0,
    );
  }

  Future<void> _cacheExpenseOffline({
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    final entry = ExpenseEntry(
      id: 'local-expense-${DateTime.now().microsecondsSinceEpoch}',
      expenseDate: expenseDate,
      category: category.trim(),
      amount: amount,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
    );

    final existing = (await _localStoreService.readList(
      LocalStoreService.expenseEntriesKey,
    )).map(ExpenseEntry.fromMap).toList();
    final merged = [entry, ...existing]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    await _localStoreService.writeList(
      LocalStoreService.expenseEntriesKey,
      merged.map((item) => item.toMap()).toList(),
    );

    await _updateSummaryCache(
      totalSalesDelta: 0,
      totalPaidDelta: 0,
      totalBalanceDelta: 0,
      estimatedProfitDelta: 0,
      totalExpensesDelta: amount,
      openLoansDelta: 0,
    );
  }

  Future<void> _updateSummaryCache({
    required double totalSalesDelta,
    required double totalPaidDelta,
    required double totalBalanceDelta,
    required double estimatedProfitDelta,
    required double totalExpensesDelta,
    required int openLoansDelta,
  }) async {
    final currentMap = await _localStoreService.readMap(
      LocalStoreService.financeSummaryKey,
    );
    final current = currentMap == null
        ? const FinanceSummary.empty()
        : FinanceSummary.fromMap(currentMap);
    final next = FinanceSummary(
      totalSales: current.totalSales + totalSalesDelta,
      totalPaid: current.totalPaid + totalPaidDelta,
      totalBalance: (current.totalBalance + totalBalanceDelta)
          .clamp(0, double.infinity)
          .toDouble(),
      estimatedProfit: current.estimatedProfit + estimatedProfitDelta,
      totalExpenses: (current.totalExpenses + totalExpensesDelta)
          .clamp(0, double.infinity)
          .toDouble(),
      netProfit: (current.netProfit + estimatedProfitDelta - totalExpensesDelta)
          .toDouble(),
      openLoans: current.openLoans + openLoansDelta,
    );
    await _localStoreService.writeMap(
      LocalStoreService.financeSummaryKey,
      next.toMap(),
    );
  }
}
