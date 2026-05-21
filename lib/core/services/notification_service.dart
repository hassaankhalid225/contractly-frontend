import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/contract_model.dart';
import '../models/payment_model.dart';

/// Local notifications + scheduling for contract & payment reminders.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'contractly_reminders';
  static const String _channelName = 'Contract Reminders';
  static const String _channelDesc =
      'Reminders for contract expiration and payment due dates.';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(settings);

    // Request runtime permissions (Android 13+ / iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static int _idFor(String key) {
    int hash = 0;
    for (final code in key.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  static Future<void> showInstant({
    required String id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(_idFor(id), title, body, _details);
  }

  static Future<void> _schedule({
    required String id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        _idFor(id),
        title,
        body,
        tzWhen,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[Notifications] Schedule failed: $e');
    }
  }

  static Future<void> cancel(String id) async {
    await init();
    await _plugin.cancel(_idFor(id));
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Schedule reminders for a contract: 14 days, 7 days, 1 day before end_date.
  /// Each reminder fires at 10 AM local time on its day.
  static Future<void> scheduleContractReminders(ContractModel contract) async {
    final end = contract.endDate;
    if (end == null) return;
    final base = 'contract_${contract.id}';
    await cancel('${base}_14d');
    await cancel('${base}_7d');
    await cancel('${base}_1d');

    Future<void> at(int daysBefore, String body) {
      final day = end.subtract(Duration(days: daysBefore));
      final at10am = DateTime(day.year, day.month, day.day, 10);
      return _schedule(
        id: '${base}_${daysBefore}d',
        when: at10am,
        title: '"${contract.title}"',
        body: body,
      );
    }

    await at(14, 'Contract expiring in 14 days');
    await at(7, 'Contract expiring in 7 days');
    await at(1, 'Contract expires tomorrow!');
  }

  /// Schedule a single reminder at the payment due date.
  static Future<void> schedulePaymentReminder(
    PaymentModel payment,
    String contractTitle,
  ) async {
    final id = 'payment_${payment.id}';
    await cancel(id);
    if (payment.status == 'paid') return;
    await _schedule(
      id: id,
      when: payment.dueDate,
      title: 'Payment due',
      body:
          'Payment of ${payment.currency} ${payment.amount.toStringAsFixed(2)} due today for "$contractTitle".',
    );
  }
}
