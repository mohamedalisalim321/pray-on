// lib/services/notification_service.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pray_on/services/adhan_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../models/my_prayer.dart';
import 'settings_service.dart';

class NotiService {
  NotiService._();
  static final instance = NotiService._();
  final SettingsService _settings = SettingsService.instance;
  final AdhanService _adhanService = AdhanService.instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static int mainNotificationId(Prayer p) => p.index + 1;
  static int preAlertNotificationId(Prayer p) => p.index + 101;
  static const int testNotificationId = 9999;

  // 👈 NEW: Alarm IDs for Adhan playback triggers
  static int adhanAlarmId(Prayer p) => p.index + 1001;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // await _createNotificationChannels();
    // await _requestPermissions();

    // 👈 Initialize AdhanService early
    await _adhanService.initialize();

    _initialized = true;
    print('✅ NotiService initialized');
  }

  // ... [_createNotificationChannels] and [_requestPermissions] remain unchanged ...

  // ---------------------------------------------------------------------------
  // ✅ NEW: Combined Method - Show Notification + Play Full Adhan
  // ---------------------------------------------------------------------------
  Future<void> _triggerPrayerAlert(MyPrayer prayer) async {
    print('🕌 Triggering alert for: ${prayer.name}');

    // 1️⃣ Show visual notification (silent - no sound, we handle audio separately)
    await _showPrayerNotification(prayer, playSound: false);

    // 2️⃣ Play FULL Adhan via AdhanService (foreground + background)
    if (_settings.soundEnabled) {
      await _adhanService.playPrayerAdhan(prayerName: prayer.name);
    }
  }

  // ---------------------------------------------------------------------------
  // Updated: Schedule with Alarm + Notification
  // ---------------------------------------------------------------------------
  Future<void> schedulePrayerNotifications(List<MyPrayer> prayers) async {
    print('📅 Scheduling notifications for ${prayers.length} prayers');
    await cancelAllPrayerNotifications();

    final now = DateTime.now();
    final enabledPrayers = prayers
        .where((p) =>
            _settings.shouldNotifyForPrayer(p.prayer) && p.time.isAfter(now))
        .toList();

    final prayersToSchedule = _settings.onlyNextPrayer
        ? (enabledPrayers.isNotEmpty ? [enabledPrayers.first] : <MyPrayer>[])
        : enabledPrayers;

    for (final prayer in prayersToSchedule) {
      // 🎯 Schedule MAIN prayer: Alarm (for Adhan) + Notification (visual)
      await _schedulePrayerWithAlarm(prayer);

      // 🔔 Pre-alerts (notification only, no full Adhan)
      if (_settings.preAlertsEnabled) {
        final preAlertTime = prayer.time.subtract(
          Duration(minutes: _settings.preAlertMinutes),
        );
        if (preAlertTime.isAfter(now)) {
          await _schedulePreAlert(prayer, preAlertTime);
        }
      }
    }
    print('✅ Scheduled ${prayersToSchedule.length} prayer alerts');
  }

  /// 👈 NEW: Schedule exact-time alarm + notification for prayer
  Future<void> _schedulePrayerWithAlarm(MyPrayer prayer) async {
    final prayerTime = tz.TZDateTime.from(prayer.time, tz.local);
    final alarmId = adhanAlarmId(prayer.prayer);

    // 📱 Show notification at prayer time (visual only)
    await _plugin.zonedSchedule(
      mainNotificationId(prayer.prayer),
      '🕌 وقت الصلاة: ${prayer.name}',
      'حان وقت صلاة ${prayer.name}',
      prayerTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer Reminders',
          channelDescription: 'Notifications when prayer time enters',
          importance: Importance.high,
          priority: Priority.high,
          playSound:
              false, // 👈 Disable notification sound - we play full Adhan separately
          enableVibration: _settings.vibrationEnabled,
          enableLights: true,
          color: const Color(0xFF5E35B1),
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: prayer.prayer.name,
    );

    // ⏰ Schedule Android alarm to trigger FULL Adhan playback at exact time
    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        prayerTime,
        alarmId,
        _adhanAlarmCallback,
        exact: true,
        wakeup: true,
      );
      print('⏰ Scheduled alarm for ${prayer.name} at $prayerTime');
    }
  }

  // ---------------------------------------------------------------------------
  // 👈 NEW: Alarm Callback - Runs when exact prayer time arrives
  // ---------------------------------------------------------------------------
  @pragma('vm:entry-point')
  static Future<void> _adhanAlarmCallback(int alarmId) async {
    // ⚠️ This runs in a separate isolate - minimal setup needed
    print('🔔 Alarm fired: $alarmId');

    // Re-initialize services if needed (simplified example)
    final adhanService = AdhanService.instance;
    await adhanService.initialize();

    // Extract prayer name from alarmId (simple mapping)
    final prayerIndex = alarmId - 1001;
    if (prayerIndex >= 0 && prayerIndex < Prayer.values.length) {
      final prayer = Prayer.values[prayerIndex];
      await adhanService.playPrayerAdhan(prayerName: prayer.name);
    }
  }

  // ---------------------------------------------------------------------------
  // Notification Display Helper (reused)
  // ---------------------------------------------------------------------------
  Future<void> _showPrayerNotification(MyPrayer prayer,
      {bool playSound = true}) async {
    final androidDetails = AndroidNotificationDetails(
      'prayer_reminders',
      'Prayer Reminders',
      channelDescription: 'Notifications when prayer time enters',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound && _settings.soundEnabled,
      enableVibration: _settings.vibrationEnabled,
      // sound: playSound && _settings.notificationSound != 'default'
      //     ? RawResourceAndroidNotificationSound(_settings.notificationSound)
      //     : null,
      enableLights: true,
      color: const Color(0xFF5E35B1),
    );

    await _plugin.zonedSchedule(
      mainNotificationId(prayer.prayer),
      '🕌 وقت الصلاة: ${prayer.name}',
      'حان وقت صلاة ${prayer.name}',
      tz.TZDateTime.from(prayer.time, tz.local),
      NotificationDetails(android: androidDetails),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: prayer.prayer.name,
    );
  }

  // ---------------------------------------------------------------------------
  // Pre-Alert Scheduling (unchanged, notification only)
  // ---------------------------------------------------------------------------
  Future<void> _schedulePreAlert(MyPrayer prayer, DateTime preTime) async {
    final tzPreTime = tz.TZDateTime.from(preTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'prayer_prealert_reminders',
      'Prayer Pre-Alerts',
      channelDescription: 'Reminders before prayer time',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      color: Color(0xFF1565C0),
    );

    await _plugin.zonedSchedule(
      preAlertNotificationId(prayer.prayer),
      '⏰ قريباً: ${prayer.name}',
      'متبقي 10 دقائق على صلاة ${prayer.name}',
      tzPreTime,
      const NotificationDetails(android: androidDetails),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '${prayer.prayer.name}_prealert',
    );
    print('⏰ Scheduled pre-alert: ${prayer.name} at $tzPreTime');
  }

  // ---------------------------------------------------------------------------
  // Tap Handlers
  // ---------------------------------------------------------------------------
  void _handleNotificationTap(NotificationResponse response) {
    final prayerName = response.payload;
    print('🔔 Notification tapped: $prayerName');

    // 👈 Play Adhan if not already playing when user taps
    if (_adhanService.isIdle && _settings.soundEnabled) {
      _adhanService.playPrayerAdhan(prayerName: prayerName);
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) async {
    print('🔔 Background tap: ${response.payload}');
    await AdhanService.instance.playPrayerAdhan(prayerName: response.payload);
  }

  // ---------------------------------------------------------------------------
  // Cancellation (updated to cancel alarms too)
  // ---------------------------------------------------------------------------
  Future<void> cancelAllPrayerNotifications() async {
    await _plugin.cancelAll();

    // 👈 Cancel all scheduled alarms
    if (Platform.isAndroid) {
      for (final prayer in Prayer.values) {
        await AndroidAlarmManager.cancel(adhanAlarmId(prayer));
      }
    }
    print('🗑️ Cancelled all prayer notifications & alarms');
  }

  Future<void> cancelPrayerNotification(Prayer prayer) async {
    await _plugin.cancel(mainNotificationId(prayer));
    await _plugin.cancel(preAlertNotificationId(prayer));

    // 👈 Cancel corresponding alarm
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(adhanAlarmId(prayer));
    }
    print('🗑️ Cancelled alerts for ${prayer.name}');
  }

  /// Debug: Print all pending notifications (Android + iOS)
  Future<void> debugScheduledNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      print('📋 Pending notifications: ${pending.length}');

      if (pending.isEmpty) {
        print('⚠️  No pending notifications found!');
        return;
      }

      for (final req in pending) {
        print('  • ID: ${req.id}');
        print('    Title: ${req.title}');
        print('    Body: ${req.body}');
        print('    Payload: ${req.payload}');
        print('    ---');
      }
    } catch (e) {
      print('❌ Error fetching pending notifications: $e');
    }
  }

  /// Check system notification status
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};

    status['initialized'] = _initialized;

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      status['notifications_enabled'] =
          await androidImpl?.areNotificationsEnabled();
      status['exact_alarms_allowed'] =
          await androidImpl?.canScheduleExactNotifications();
    }

    status['pending_count'] =
        (await _plugin.pendingNotificationRequests()).length;

    return status;
  }

  // ---------------------------------------------------------------------------
  // Permission Checks
  // ---------------------------------------------------------------------------
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS: assume enabled if app is running
  }
}
