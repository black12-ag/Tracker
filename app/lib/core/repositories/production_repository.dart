import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductionRepository {
  ProductionRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  Future<List<ProductionEntryModel>> fetchRecentEntries({int limit = 8}) async {
    try {
      final rows = await _client
          .from('production_entries')
          .select(
            'id, produced_on, quantity_units, notes, product_sizes!inner(label, liters)',
          )
          .order('produced_on', ascending: false)
          .limit(limit);

      final entries = rows
          .map<ProductionEntryModel>(
            (row) => ProductionEntryModel(
              id: row['id'] as String,
              producedOn: DateTime.parse(row['produced_on'] as String),
              quantityUnits: row['quantity_units'] as int? ?? 0,
              notes: row['notes'] as String?,
              sizeLabel: row['product_sizes']['label'] as String? ?? '',
              sizeLiters: _asDouble(row['product_sizes']['liters']),
            ),
          )
          .toList();
      await _localStoreService.writeList(
        LocalStoreService.productionEntriesKey,
        entries.map((item) => item.toMap()).toList(),
      );
      return entries;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readList(
        LocalStoreService.productionEntriesKey,
      );
      return cached.map(ProductionEntryModel.fromMap).take(limit).toList();
    }
  }

  Future<int> fetchTotalProducedOn(DateTime date) async {
    final rows = await _client
        .from('production_entries')
        .select('quantity_units')
        .eq('produced_on', date.toIso8601String().split('T').first);

    return rows.fold<int>(
      0,
      (sum, row) => sum + (row['quantity_units'] as int? ?? 0),
    );
  }

  Future<void> createEntryOnline({
    required DateTime producedOn,
    required String sizeId,
    required int quantityUnits,
    required String? notes,
    required String createdBy,
  }) async {
    await _client.from('production_entries').insert({
      'produced_on': producedOn.toIso8601String().split('T').first,
      'size_id': sizeId,
      'quantity_units': quantityUnits,
      'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      'created_by': createdBy,
    });
  }

  Future<SyncWriteResult> createEntry({
    required DateTime producedOn,
    required String sizeId,
    required int quantityUnits,
    required String? notes,
    required String createdBy,
    required String sizeLabel,
    required double sizeLiters,
  }) async {
    try {
      await createEntryOnline(
        producedOn: producedOn,
        sizeId: sizeId,
        quantityUnits: quantityUnits,
        notes: notes,
        createdBy: createdBy,
      );
      return const SyncWriteResult.synced('Production entry saved.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      final localEntry = ProductionEntryModel(
        id: 'local-production-${DateTime.now().microsecondsSinceEpoch}',
        producedOn: producedOn,
        quantityUnits: quantityUnits,
        sizeLabel: sizeLabel,
        sizeLiters: sizeLiters,
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      );
      final cachedEntries = await _localStoreService.readList(
        LocalStoreService.productionEntriesKey,
      );
      await _localStoreService.writeList(
        LocalStoreService.productionEntriesKey,
        [localEntry.toMap(), ...cachedEntries].take(20).toList(),
      );
      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: OfflineSyncActionType.createProductionEntry,
          payload: {
            'produced_on': producedOn.toIso8601String(),
            'size_id': sizeId,
            'quantity_units': quantityUnits,
            'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
            'created_by': createdBy,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const SyncWriteResult.queued();
    }
  }
}
