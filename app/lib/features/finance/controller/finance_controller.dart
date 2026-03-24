import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/finance/models/expense_entry.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_record.dart';
import 'package:liquid_soap_tracker/features/finance/models/finance_summary.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchSummary();
});

final financeRecordsProvider = FutureProvider<List<FinanceRecord>>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchFinanceRecords(limit: 20);
});

final expenseEntriesProvider = FutureProvider<List<ExpenseEntry>>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchExpenses(limit: 20);
});

final pendingFinanceDispatchesProvider =
    FutureProvider<List<SalesDispatchModel>>((ref) async {
      return ref
          .watch(financeRepositoryProvider)
          .fetchPendingFinanceDispatches();
    });
