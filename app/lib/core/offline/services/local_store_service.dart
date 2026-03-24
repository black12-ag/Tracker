import 'dart:convert';

import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStoreService {
  static const String profileKey = 'cached_profile';
  static const String customersKey = 'cached_customers';
  static const String productionEntriesKey = 'cached_production_entries';
  static const String financeSummaryKey = 'cached_finance_summary';
  static const String financeRecordsKey = 'cached_finance_records';
  static const String expenseEntriesKey = 'cached_expense_entries';
  static const String queueKey = 'offline_sync_queue';
  static const String lastSyncKey = 'last_sync_at';

  static String productBundleKey(bool owner) =>
      owner ? 'cached_product_bundle_owner' : 'cached_product_bundle_operator';

  static String salesDispatchesKey(bool owner) => owner
      ? 'cached_sales_dispatches_owner'
      : 'cached_sales_dispatches_operator';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<Map<String, dynamic>?> readMap(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    return (jsonDecode(raw) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<OfflineSyncAction>> readQueue() async {
    final items = await readList(queueKey);
    return items.map(OfflineSyncAction.fromMap).toList();
  }

  Future<void> writeQueue(List<OfflineSyncAction> actions) async {
    await writeList(queueKey, actions.map((item) => item.toMap()).toList());
  }

  Future<void> enqueue(OfflineSyncAction action) async {
    final items = await readQueue();
    await writeQueue([...items, action]);
  }

  Future<int> pendingQueueCount() async {
    final items = await readQueue();
    return items.length;
  }

  Future<void> setLastSyncAt(DateTime value) async {
    await _storage.write(key: lastSyncKey, value: value.toIso8601String());
  }

  Future<DateTime?> getLastSyncAt() async {
    final raw = await _storage.read(key: lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> clearAllCachedData() async {
    for (final key in [
      profileKey,
      customersKey,
      productionEntriesKey,
      financeSummaryKey,
      financeRecordsKey,
      expenseEntriesKey,
      queueKey,
      lastSyncKey,
      productBundleKey(true),
      productBundleKey(false),
      salesDispatchesKey(true),
      salesDispatchesKey(false),
    ]) {
      await _storage.delete(key: key);
    }
  }
}
