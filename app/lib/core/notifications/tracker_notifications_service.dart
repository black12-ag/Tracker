import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/repositories/tracker_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerNotificationsService {
  static const _pendingTargetKey = 'pending_notification_target';
  static const _lastShipmentNotificationKey = 'last_shipment_notification_at';
  static const _lastReceiveNotificationKey = 'last_receive_notification_at';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await _storePendingTarget(response.payload);
      },
    );

    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      await _storePendingTarget(
        launchDetails?.notificationResponse?.payload,
      );
    }

    _initialized = true;
  }

  Future<void> syncOverdueBalanceNotifications({
    required AppProfile profile,
    required TrackerRepository repository,
  }) async {
    if (!profile.isOwner) {
      return;
    }

    await initialize();
    final alerts = await repository.listSalesBalanceAlerts();
    final now = DateTime.now();

    for (final alert in alerts) {
      final overdueLevel =
          (alert['overdue_level'] as String? ?? 'pending').toLowerCase();
      if (overdueLevel != 'late' && overdueLevel != 'severe') {
        continue;
      }

      final nextReminderRaw = alert['next_reminder_at'] as String?;
      final nextReminderAt = nextReminderRaw == null
          ? now
          : DateTime.tryParse(nextReminderRaw)?.toLocal() ?? now;
      if (nextReminderAt.isAfter(now)) {
        continue;
      }

      final customerName = alert['customer_name'] as String? ?? 'Customer';
      final balanceAmount = (alert['balance_amount'] as num?)?.toDouble() ?? 0;
      final daysOverdue = (alert['days_overdue'] as num?)?.toInt() ?? 0;
      final notificationId =
          (alert['sales_order_id'] as String).hashCode & 0x7fffffff;

      await _plugin.show(
        notificationId,
        'Payment follow-up needed',
        '$customerName still owes Br ${balanceAmount.toStringAsFixed(2)} • $daysOverdue day(s) late.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tracker_loans',
            'Loan reminders',
            channelDescription: 'Overdue customer payment reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'loan_records',
      );

      await repository.markSalesOrderReminderSent(
        salesOrderId: alert['sales_order_id'] as String,
      );
    }

    await _syncPendingOrderNotifications(
      repository: repository,
      now: now,
      type: _PendingOrderNotificationType.shipment,
    );
    await _syncPendingOrderNotifications(
      repository: repository,
      now: now,
      type: _PendingOrderNotificationType.receive,
    );
  }

  Future<String?> consumePendingTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final target = prefs.getString(_pendingTargetKey);
    if (target == null || target.isEmpty) {
      return null;
    }
    await prefs.remove(_pendingTargetKey);
    return target;
  }

  Future<void> _storePendingTarget(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingTargetKey, payload);
  }

  Future<void> _syncPendingOrderNotifications({
    required TrackerRepository repository,
    required DateTime now,
    required _PendingOrderNotificationType type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastKey = type == _PendingOrderNotificationType.shipment
        ? _lastShipmentNotificationKey
        : _lastReceiveNotificationKey;
    final payload = type == _PendingOrderNotificationType.shipment
        ? 'shipment'
        : 'receive';
    final title = type == _PendingOrderNotificationType.shipment
        ? 'Orders waiting to ship'
        : 'Orders waiting to receive';
    final bodyLabel = type == _PendingOrderNotificationType.shipment
        ? 'sales order'
        : 'purchase order';

    final rawLast = prefs.getString(lastKey);
    final lastNotificationAt = rawLast == null ? null : DateTime.tryParse(rawLast);
    if (lastNotificationAt != null &&
        now.difference(lastNotificationAt).inHours < 12) {
      return;
    }

    final orders = type == _PendingOrderNotificationType.shipment
        ? await repository.listPendingShipments()
        : await repository.listPendingReceives();
    if (orders.isEmpty) {
      return;
    }

    await _plugin.show(
      type == _PendingOrderNotificationType.shipment ? 71001 : 71002,
      title,
      '${orders.length} $bodyLabel${orders.length == 1 ? '' : 's'} need action.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tracker_orders',
          'Order updates',
          channelDescription: 'Pending shipment and receive reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
    await prefs.setString(lastKey, now.toIso8601String());
  }
}

enum _PendingOrderNotificationType { shipment, receive }
