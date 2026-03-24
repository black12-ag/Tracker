import 'dart:typed_data';

import 'package:liquid_soap_tracker/core/models/sync_write_result.dart';
import 'package:liquid_soap_tracker/core/offline/models/offline_sync_action.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  ProductRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

  String? _buildProductImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    return _client.storage.from('product-media').getPublicUrl(path);
  }

  Future<ProductSetupBundle> fetchBundle({required bool owner}) async {
    try {
      final inventoryRows = await _client
          .from('size_inventory_summary')
          .select()
          .order('liters');

      String productName = 'Liquid Soap';
      double? defaultCostPerLiter;
      final pricesBySize = <String, double>{};

      String? productImagePath;

      if (owner) {
        final settings = await _client
            .from('product_settings')
            .select()
            .eq('id', 1)
            .single();

        productName = settings['product_name'] as String? ?? 'Liquid Soap';
        defaultCostPerLiter = _asDouble(settings['default_cost_per_liter']);
        productImagePath = settings['product_image_path'] as String?;

        final priceRows = await _client.from('size_prices').select();
        for (final priceRow in priceRows) {
          pricesBySize[priceRow['size_id'] as String] = _asDouble(
            priceRow['unit_price'],
          );
        }
      } else {
        final publicRows = await _client.rpc('get_product_public_settings');
        if (publicRows is List && publicRows.isNotEmpty) {
          productName =
              publicRows.first['product_name'] as String? ?? productName;
          productImagePath = publicRows.first['product_image_path'] as String?;
        }
      }

      final sizes = inventoryRows
          .map<ProductSizeSetting>(
            (row) => ProductSizeSetting(
              id: row['size_id'] as String,
              label: row['label'] as String,
              liters: _asDouble(row['liters']),
              lowStockThreshold: row['low_stock_threshold'] as int? ?? 0,
              active: true,
              unitPrice: pricesBySize[row['size_id'] as String],
              producedUnits: row['produced_units'] as int? ?? 0,
              soldUnits: row['sold_units'] as int? ?? 0,
              currentStockUnits: row['current_stock_units'] as int? ?? 0,
              isLowStock: row['is_low_stock'] as bool? ?? false,
            ),
          )
          .toList();

      final bundle = ProductSetupBundle(
        productName: productName,
        defaultCostPerLiter: defaultCostPerLiter,
        productImagePath: productImagePath,
        productImageUrl: _buildProductImageUrl(productImagePath),
        sizes: sizes,
        canSeeFinancials: owner,
      );
      await _localStoreService.writeMap(
        LocalStoreService.productBundleKey(owner),
        bundle.toMap(),
      );
      if (owner) {
        await _localStoreService.writeMap(
          LocalStoreService.productBundleKey(false),
          ProductSetupBundle(
            productName: productName,
            defaultCostPerLiter: null,
            productImagePath: productImagePath,
            productImageUrl: _buildProductImageUrl(productImagePath),
            sizes: sizes.map((size) => size.copyWith(unitPrice: null)).toList(),
            canSeeFinancials: false,
          ).toMap(),
        );
      }
      return bundle;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      final cached = await _localStoreService.readMap(
        LocalStoreService.productBundleKey(owner),
      );
      if (cached != null) {
        return ProductSetupBundle.fromMap(cached);
      }
      rethrow;
    }
  }

  Future<void> saveSetupOnline({
    required String productName,
    required double defaultCostPerLiter,
    required List<Map<String, dynamic>> sizesPayload,
    String? productImagePath,
  }) async {
    await _client.from('product_settings').upsert({
      'id': 1,
      'product_name': productName.trim(),
      'default_cost_per_liter': defaultCostPerLiter,
      'product_image_path': productImagePath,
    });

    await _client
        .from('product_sizes')
        .upsert(
          sizesPayload
              .map(
                (size) => {
                  'id': size['id'],
                  'label': size['label'],
                  'liters': size['liters'],
                  'low_stock_threshold': size['low_stock_threshold'],
                  'active': size['active'],
                },
              )
              .toList(),
          onConflict: 'id',
        );

    final pricedSizes = sizesPayload
        .where((size) => size['unit_price'] != null)
        .map(
          (size) => {
            'size_id': size['id'],
            'unit_price': size['unit_price'],
          },
        )
        .toList();
    if (pricedSizes.isNotEmpty) {
      await _client.from('size_prices').upsert(pricedSizes, onConflict: 'size_id');
    }

    final nullPriceIds = sizesPayload
        .where((size) => size['unit_price'] == null)
        .map((size) => size['id'] as String)
        .toList();
    if (nullPriceIds.isNotEmpty) {
      await _client.from('size_prices').delete().inFilter('size_id', nullPriceIds);
    }
  }

  Future<SyncWriteResult> saveSetup({
    required String productName,
    required double defaultCostPerLiter,
    required List<ProductSizeSetting> sizes,
    String? productImagePath,
    String? productImageUrl,
  }) async {
    final ownerBundle = ProductSetupBundle(
      productName: productName,
      defaultCostPerLiter: defaultCostPerLiter,
      productImagePath: productImagePath,
      productImageUrl:
          productImageUrl ?? _buildProductImageUrl(productImagePath),
      sizes: sizes,
      canSeeFinancials: true,
    );
    final publicBundle = ProductSetupBundle(
      productName: productName,
      defaultCostPerLiter: null,
      productImagePath: productImagePath,
      productImageUrl: productImageUrl ?? _buildProductImageUrl(productImagePath),
      sizes: sizes.map((size) => size.copyWith(unitPrice: null)).toList(),
      canSeeFinancials: false,
    );

    try {
      await saveSetupOnline(
        productName: productName,
        defaultCostPerLiter: defaultCostPerLiter,
        sizesPayload: sizes.map((size) => size.toMap()).toList(),
        productImagePath: productImagePath,
      );
      await _localStoreService.writeMap(
        LocalStoreService.productBundleKey(true),
        ownerBundle.toMap(),
      );
      await _localStoreService.writeMap(
        LocalStoreService.productBundleKey(false),
        publicBundle.toMap(),
      );
      return const SyncWriteResult.synced('Product saved.');
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      await _localStoreService.writeMap(
        LocalStoreService.productBundleKey(true),
        ownerBundle.toMap(),
      );
      await _localStoreService.writeMap(
        LocalStoreService.productBundleKey(false),
        publicBundle.toMap(),
      );

      await _localStoreService.enqueue(
        OfflineSyncAction(
          id: 'queue-${DateTime.now().microsecondsSinceEpoch}',
          type: OfflineSyncActionType.saveProductSetup,
          payload: {
            'product_name': productName,
            'default_cost_per_liter': defaultCostPerLiter,
            'product_image_path': productImagePath,
            'sizes': sizes.map((size) => size.toMap()).toList(),
          },
          createdAt: DateTime.now(),
        ),
      );
      return const SyncWriteResult.queued();
    }
  }

  Future<(String path, String url)> uploadProductImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final sanitizedExtension = fileExtension.toLowerCase().replaceAll('.', '');
    final path =
        'product/product-${DateTime.now().microsecondsSinceEpoch}.$sanitizedExtension';

    await _client.storage
        .from('product-media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: switch (sanitizedExtension) {
              'png' => 'image/png',
              'webp' => 'image/webp',
              _ => 'image/jpeg',
            },
          ),
        );

    return (path, _buildProductImageUrl(path)!);
  }
}
