import 'package:image_picker/image_picker.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackerRepository {
  TrackerRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  Future<Map<String, dynamic>> fetchHomeBundle({
    required bool owner,
    String period = 'monthly',
  }) async {
    final cacheKey = owner
        ? LocalStoreService.homeBundleOwnerKey
        : LocalStoreService.homeBundleStaffKey;

    try {
      final summaryResponse = await _client.rpc(
        'home_overview_summary',
        params: {'p_period': period},
      );
      final summaryRows = _asListOfMaps(summaryResponse);
      final summary = summaryRows.isEmpty ? <String, dynamic>{} : summaryRows.first;

      final recentSales = _asListOfMaps(
        await _client
            .from('sales_orders')
            .select('''
              id,
              order_code,
              order_date,
              due_date,
              shipment_date,
              status,
              total_amount,
              paid_amount,
              balance_amount,
              payment_count,
              reminder_state,
              partners(name, phone)
            ''')
            .order('created_at', ascending: false)
            .limit(5),
      );

      final recentPurchases = _asListOfMaps(
        await _client
            .from('purchase_orders')
            .select('''
              id,
              order_code,
              order_date,
              receive_date,
              status,
              total_amount,
              paid_amount,
              balance_amount,
              partners(name, phone)
            ''')
            .order('created_at', ascending: false)
            .limit(5),
      );

      final bundle = {
        'summary': summary,
        'recent_sales': recentSales,
        'recent_purchases': recentPurchases,
      };
      await _localStoreService.writeMap(cacheKey, bundle);
      return bundle;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      return await _localStoreService.readMap(cacheKey) ??
          {
            'summary': <String, dynamic>{},
            'recent_sales': <Map<String, dynamic>>[],
            'recent_purchases': <Map<String, dynamic>>[],
          };
    }
  }

  Future<List<Map<String, dynamic>>> listPartners({
    String search = '',
  }) async {
    try {
      final response = await _client
          .from('partners')
          .select()
          .order('created_at', ascending: false);

      final rows = _asListOfMaps(response).where((row) {
        if (search.trim().isEmpty) {
          return true;
        }
        final query = search.trim().toLowerCase();
        final name = (row['name'] as String? ?? '').toLowerCase();
        final phone = (row['phone'] as String? ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();

      await _localStoreService.writeList(LocalStoreService.partnersKey, rows);
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.partnersKey);
    }
  }

  Future<Map<String, dynamic>> createPartner({
    required String createdBy,
    required String name,
    String? phone,
    String partnerType = 'customer',
    String? note,
  }) async {
    final response = await _client
        .from('partners')
        .insert({
          'name': name.trim(),
          'phone': _nullIfBlank(phone),
          'partner_type': partnerType,
          'note': _nullIfBlank(note),
          'created_by': createdBy,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> listInventoryItems({
    String search = '',
  }) async {
    try {
      final stockRows = _asListOfMaps(
        await _client.from('inventory_stock_summary').select(),
      );
      final stockByItemId = {
        for (final row in stockRows) row['item_id'] as String: row,
      };

      final itemRows = _asListOfMaps(
        await _client
            .from('inventory_items')
            .select('''
              id,
              sku,
              name,
              unit_type,
              bought_price,
              selling_price,
              description,
              active,
              inventory_item_images(id, storage_path, sort_order)
            ''')
            .order('created_at', ascending: false),
      );

      final normalizedSearch = search.trim().toLowerCase();
      final result = <Map<String, dynamic>>[];
      for (final row in itemRows) {
        final name = (row['name'] as String? ?? '').toLowerCase();
        final sku = (row['sku'] as String? ?? '').toLowerCase();
        if (normalizedSearch.isNotEmpty &&
            !name.contains(normalizedSearch) &&
            !sku.contains(normalizedSearch)) {
          continue;
        }

        final images = _asListOfMaps(row['inventory_item_images']);
        images.sort(
          (left, right) => (left['sort_order'] as int? ?? 0).compareTo(
            right['sort_order'] as int? ?? 0,
          ),
        );

        final firstImagePath = images.isEmpty
            ? null
            : images.first['storage_path'] as String?;
        final imageUrl = firstImagePath == null
            ? null
            : await _createSignedImageUrl(firstImagePath);

        result.add({
          ...row,
          'current_stock':
              (stockByItemId[row['id']]?['current_stock'] as num?)?.toDouble() ??
              0,
          'image_url': imageUrl,
          'images': images,
        });
      }

      await _localStoreService.writeList(
        LocalStoreService.inventoryItemsKey,
        result,
      );
      return result;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.inventoryItemsKey);
    }
  }

  Future<Map<String, dynamic>> saveInventoryItem({
    String? itemId,
    required String createdBy,
    required String name,
    required String unitType,
    required double boughtPrice,
    required double sellingPrice,
    String? description,
    List<XFile> images = const [],
  }) async {
    final payload = {
      'name': name.trim(),
      'unit_type': unitType.trim(),
      'bought_price': boughtPrice,
      'selling_price': sellingPrice,
      'description': _nullIfBlank(description),
      'active': true,
    };

    late final Map<String, dynamic> itemRow;
    if (itemId == null) {
      final response = await _client
          .from('inventory_items')
          .insert({...payload, 'created_by': createdBy})
          .select()
          .single();
      itemRow = Map<String, dynamic>.from(response);
    } else {
      final response = await _client
          .from('inventory_items')
          .update(payload)
          .eq('id', itemId)
          .select()
          .single();
      itemRow = Map<String, dynamic>.from(response);
    }

    if (images.isNotEmpty) {
      await _uploadInventoryImages(
        itemId: itemRow['id'] as String,
        createdBy: createdBy,
        images: images,
      );
    }

    return itemRow;
  }

  Future<List<Map<String, dynamic>>> listSalesOrders({
    String search = '',
  }) async {
    try {
      final rows = _asListOfMaps(
        await _client
            .from('sales_orders')
            .select('''
              id,
              order_code,
              order_date,
              due_date,
              shipment_date,
              status,
              note,
              total_amount,
              paid_amount,
              balance_amount,
              payment_count,
              last_payment_at,
              reminder_state,
              partners(id, name, phone),
              sales_order_items(
                id,
                quantity,
                unit_price,
                unit_cost_snapshot,
                inventory_items(id, name, sku, unit_type)
              )
            ''')
            .order('created_at', ascending: false),
      );

      final filtered = rows.where((row) {
        if (search.trim().isEmpty) {
          return true;
        }

        final query = search.trim().toLowerCase();
        final code = (row['order_code'] as String? ?? '').toLowerCase();
        final partnerMap = _asMap(row['partners']);
        final partnerName = (partnerMap['name'] as String? ?? '').toLowerCase();
        return code.contains(query) || partnerName.contains(query);
      }).toList();

      await _localStoreService.writeList(LocalStoreService.salesOrdersKey, filtered);
      return filtered;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.salesOrdersKey);
    }
  }

  Future<String> createSalesOrder({
    required String createdBy,
    String? partnerId,
    required DateTime orderDate,
    DateTime? shipmentDate,
    DateTime? dueDate,
    String? note,
    required double paidAmount,
    String? accountId,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderResponse = await _client
        .from('sales_orders')
        .insert({
          'partner_id': partnerId,
          'order_date': orderDate.toIso8601String().split('T').first,
          'shipment_date': shipmentDate?.toIso8601String().split('T').first,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'status': 'ready',
          'note': _nullIfBlank(note),
          'paid_amount': 0,
          'account_id': _nullIfBlank(accountId),
          'created_by': createdBy,
        })
        .select()
        .single();

    final orderId = orderResponse['id'] as String;
    await _client.from('sales_order_items').insert(
      items.map((item) {
        return {
          'sales_order_id': orderId,
          'item_id': item['item_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'unit_cost_snapshot': item['unit_cost_snapshot'] ?? 0,
        };
      }).toList(),
    );

    if (paidAmount > 0 && accountId != null) {
      await _client.rpc(
        'record_sales_order_payment',
        params: {
          'p_sales_order_id': orderId,
          'p_account_id': accountId,
          'p_amount': paidAmount,
          'p_payment_date': orderDate.toIso8601String().split('T').first,
        },
      );
    }

    return orderId;
  }

  Future<void> shipSalesOrder(String orderId, {DateTime? shipmentDate}) async {
    await _client.rpc(
      'record_sales_shipment',
      params: {
        'p_sales_order_id': orderId,
        'p_shipment_date':
            (shipmentDate ?? DateTime.now()).toIso8601String().split('T').first,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listPurchaseOrders({
    String search = '',
  }) async {
    try {
      final rows = _asListOfMaps(
        await _client
            .from('purchase_orders')
            .select('''
              id,
              order_code,
              order_date,
              receive_date,
              status,
              note,
              total_amount,
              paid_amount,
              balance_amount,
              partners(id, name, phone),
              purchase_order_items(
                id,
                quantity,
                unit_price,
                inventory_items(id, name, sku, unit_type)
              )
            ''')
            .order('created_at', ascending: false),
      );

      final filtered = rows.where((row) {
        if (search.trim().isEmpty) {
          return true;
        }

        final query = search.trim().toLowerCase();
        final code = (row['order_code'] as String? ?? '').toLowerCase();
        final partnerMap = _asMap(row['partners']);
        final partnerName = (partnerMap['name'] as String? ?? '').toLowerCase();
        return code.contains(query) || partnerName.contains(query);
      }).toList();

      await _localStoreService.writeList(
        LocalStoreService.purchaseOrdersKey,
        filtered,
      );
      return filtered;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.purchaseOrdersKey);
    }
  }

  Future<String> createPurchaseOrder({
    required String createdBy,
    String? partnerId,
    required DateTime orderDate,
    DateTime? receiveDate,
    String? note,
    required double paidAmount,
    String? accountId,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderResponse = await _client
        .from('purchase_orders')
        .insert({
          'partner_id': partnerId,
          'order_date': orderDate.toIso8601String().split('T').first,
          'receive_date': receiveDate?.toIso8601String().split('T').first,
          'status': 'ready',
          'note': _nullIfBlank(note),
          'paid_amount': paidAmount,
          'account_id': _nullIfBlank(accountId),
          'created_by': createdBy,
        })
        .select()
        .single();

    final orderId = orderResponse['id'] as String;
    await _client.from('purchase_order_items').insert(
      items.map((item) {
        return {
          'purchase_order_id': orderId,
          'item_id': item['item_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
        };
      }).toList(),
    );

    return orderId;
  }

  Future<void> receivePurchaseOrder(
    String orderId, {
    DateTime? receiveDate,
  }) async {
    await _client.rpc(
      'record_purchase_receipt',
      params: {
        'p_purchase_order_id': orderId,
        'p_receive_date':
            (receiveDate ?? DateTime.now()).toIso8601String().split('T').first,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listAccountSummaries() async {
    try {
      final response = await _client.rpc('account_balance_summary');
      final rows = _asListOfMaps(response);
      await _localStoreService.writeList(LocalStoreService.accountSummaryKey, rows);
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.accountSummaryKey);
    }
  }

  Future<Map<String, dynamic>> createAccount({
    required String createdBy,
    required String accountName,
    String? accountNumber,
    String? bankName,
    required String accountType,
    required double openingBalance,
  }) async {
    final response = await _client
        .from('accounts')
        .insert({
          'account_name': accountName.trim(),
          'account_number': _nullIfBlank(accountNumber),
          'bank_name': _nullIfBlank(bankName),
          'account_type': accountType,
          'opening_balance': openingBalance,
          'created_by': createdBy,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createTransfer({
    required String createdBy,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime transferDate,
    String? note,
  }) async {
    final response = await _client
        .from('account_transfers')
        .insert({
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'amount': amount,
          'transfer_date': transferDate.toIso8601String().split('T').first,
          'note': _nullIfBlank(note),
          'created_by': createdBy,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> listLoanRecords() async {
    try {
      final rows = _asListOfMaps(
        await _client
            .from('loan_records')
            .select('''
              id,
              direction,
              record_date,
              amount,
              settled_amount,
              balance_amount,
              note,
              partners(name, phone),
              accounts(account_name, account_code)
            ''')
            .order('created_at', ascending: false),
      );
      await _localStoreService.writeList(LocalStoreService.loanRecordsKey, rows);
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.loanRecordsKey);
    }
  }

  Future<List<Map<String, dynamic>>> listSalesBalanceAlerts() async {
    try {
      final rows = _asListOfMaps(await _client.rpc('sales_balance_alerts'));
      await _localStoreService.writeList(
        LocalStoreService.salesBalanceAlertsKey,
        rows,
      );
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(
        LocalStoreService.salesBalanceAlertsKey,
      );
    }
  }

  Future<void> recordSalesOrderPayment({
    required String salesOrderId,
    required String accountId,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    await _client.rpc(
      'record_sales_order_payment',
      params: {
        'p_sales_order_id': salesOrderId,
        'p_account_id': accountId,
        'p_amount': amount,
        'p_payment_date': paymentDate.toIso8601String().split('T').first,
        'p_note': _nullIfBlank(note),
      },
    );
  }

  Future<void> markSalesOrderReminderSent({
    required String salesOrderId,
    String? note,
  }) async {
    await _client.rpc(
      'mark_sales_order_reminder_sent',
      params: {
        'p_sales_order_id': salesOrderId,
        'p_note': _nullIfBlank(note),
      },
    );
  }

  Future<Map<String, dynamic>> createLoanRecord({
    required String createdBy,
    required String partnerId,
    required String direction,
    required DateTime recordDate,
    required double amount,
    String? accountId,
    String? note,
  }) async {
    final response = await _client
        .from('loan_records')
        .insert({
          'partner_id': partnerId,
          'direction': direction,
          'record_date': recordDate.toIso8601String().split('T').first,
          'amount': amount,
          'account_id': _nullIfBlank(accountId),
          'note': _nullIfBlank(note),
          'created_by': createdBy,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> listExpenses() async {
    try {
      final rows = _asListOfMaps(
        await _client
            .from('expense_entries')
            .select('''
              id,
              expense_date,
              category,
              amount,
              note,
              accounts(account_name, account_code)
            ''')
            .order('created_at', ascending: false),
      );
      await _localStoreService.writeList(LocalStoreService.expenseEntriesKey, rows);
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.expenseEntriesKey);
    }
  }

  Future<Map<String, dynamic>> createExpense({
    required String createdBy,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? accountId,
    String? note,
  }) async {
    final response = await _client
        .from('expense_entries')
        .insert({
          'expense_date': expenseDate.toIso8601String().split('T').first,
          'category': category.trim(),
          'amount': amount,
          'account_id': _nullIfBlank(accountId),
          'note': _nullIfBlank(note),
          'created_by': createdBy,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> listEmployees() async {
    try {
      final rows = _asListOfMaps(
        await _client
            .from('profiles')
            .select(
              'id, email, display_name, phone, role, is_active, created_by_owner, created_at',
            )
            .eq('role', 'staff')
            .eq('is_active', true)
            .not('created_by_owner', 'is', null)
            .order('created_at', ascending: false),
      );
      await _localStoreService.writeList(LocalStoreService.employeesKey, rows);
      return rows;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return _localStoreService.readList(LocalStoreService.employeesKey);
    }
  }

  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await _client.functions.invoke(
      'create-staff',
      body: {
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        response.data is Map && response.data['error'] != null
            ? response.data['error'] as String
            : 'Unable to create staff account.',
      );
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> fetchReports({String period = 'monthly'}) async {
    try {
      final salesRows = _asListOfMaps(
        await _client.rpc('sales_report_summary', params: {'p_period': period}),
      );
      final purchaseRows = _asListOfMaps(
        await _client.rpc(
          'purchase_report_summary',
          params: {'p_period': period},
        ),
      );
      final inventoryRows = _asListOfMaps(
        await _client.rpc('inventory_report_summary'),
      );
      final adjustmentRows = _asListOfMaps(
        await _client.rpc(
          'inventory_adjustment_report_summary',
          params: {'p_period': period},
        ),
      );

      final bundle = {
        'sales': salesRows.isEmpty ? <String, dynamic>{} : salesRows.first,
        'purchased': purchaseRows.isEmpty ? <String, dynamic>{} : purchaseRows.first,
        'inventory': inventoryRows.isEmpty ? <String, dynamic>{} : inventoryRows.first,
        'adjustments': adjustmentRows.isEmpty
            ? <String, dynamic>{}
            : adjustmentRows.first,
      };

      await _localStoreService.writeMap(LocalStoreService.reportsKey, bundle);
      return bundle;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }
      return await _localStoreService.readMap(LocalStoreService.reportsKey) ??
          {
            'sales': <String, dynamic>{},
            'purchased': <String, dynamic>{},
            'inventory': <String, dynamic>{},
            'adjustments': <String, dynamic>{},
          };
    }
  }

  Future<Map<String, dynamic>> fetchCurrentProfileDetails(String userId) async {
    final response = await _client
        .from('profiles')
        .select('id, email, display_name, phone, role, is_active')
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> updateCurrentProfile({
    required String userId,
    required String displayName,
    String? phone,
  }) async {
    await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'phone': _nullIfBlank(phone),
        })
        .eq('id', userId);
  }

  Future<void> addInventoryAdjustment({
    required String createdBy,
    required String itemId,
    required String movementType,
    required double quantity,
    required DateTime movementDate,
    String? note,
  }) async {
    await _client.from('stock_movements').insert({
      'item_id': itemId,
      'movement_type': movementType,
      'quantity': quantity,
      'movement_date': movementDate.toIso8601String().split('T').first,
      'note': _nullIfBlank(note),
      'created_by': createdBy,
    });
  }

  Future<List<Map<String, dynamic>>> listPendingReceives() async {
    return _asListOfMaps(
      await _client
          .from('purchase_orders')
          .select('id, order_code, order_date, status, total_amount, partners(name)')
          .inFilter('status', ['ready', 'draft'])
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> listPendingShipments() async {
    return _asListOfMaps(
      await _client
          .from('sales_orders')
          .select('id, order_code, order_date, status, total_amount, partners(name)')
          .inFilter('status', ['ready', 'draft'])
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> listInventoryAdjustments() async {
    return _asListOfMaps(
      await _client
          .from('stock_movements')
          .select('''
            id,
            movement_type,
            quantity,
            movement_date,
            note,
            inventory_items(name, sku, unit_type)
          ''')
          .inFilter('movement_type', ['adjustment_plus', 'adjustment_minus'])
          .order('created_at', ascending: false),
    );
  }

  Future<void> _uploadInventoryImages({
    required String itemId,
    required String createdBy,
    required List<XFile> images,
  }) async {
    final existingImages = _asListOfMaps(
      await _client
          .from('inventory_item_images')
          .select('id, sort_order')
          .eq('item_id', itemId)
          .order('sort_order'),
    );

    final availableSlots = 5 - existingImages.length;
    if (availableSlots <= 0) {
      return;
    }

    final uploadImages = images.take(availableSlots).toList();
    final imageRows = <Map<String, dynamic>>[];
    for (var index = 0; index < uploadImages.length; index += 1) {
      final image = uploadImages[index];
      final bytes = await image.readAsBytes();
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final path =
          '$itemId/${DateTime.now().microsecondsSinceEpoch}-$index.$extension';
      await _client.storage.from('inventory-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: image.mimeType),
          );
      imageRows.add({
        'item_id': itemId,
        'storage_path': path,
        'sort_order': existingImages.length + index,
        'created_by': createdBy,
      });
    }

    if (imageRows.isNotEmpty) {
      await _client.from('inventory_item_images').insert(imageRows);
    }
  }

  Future<String?> _createSignedImageUrl(String path) async {
    try {
      return await _client.storage
          .from('inventory-images')
          .createSignedUrl(path, 60 * 60);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic input) {
    if (input is List) {
      return input
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (input == null) {
      return const [];
    }

    return [Map<String, dynamic>.from(input as Map)];
  }

  Map<String, dynamic> _asMap(dynamic input) {
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    }

    return const {};
  }

  String? _nullIfBlank(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
