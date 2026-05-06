// ignore_for_file: avoid_print

import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/my_prayer.dart';

class NotiService {
  NotiService._();
  static final instance = NotiService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs (consistent & documented)
  static int mainNotificationId(Prayer p) => p.index + 1;
  static int preAlertNotificationId(Prayer p) => p.index + 101;
  static const int testNotificationId = 9999;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;

    // 1️⃣ Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2️⃣ Platform-specific initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // 3️⃣ Create notification channels (Android)
    await _createNotificationChannels();

    // 4️⃣ Request permissions
    await _requestPermissions();

    // 5️⃣ Debug info (optional)
    await debugScheduledNotifications();

    _initialized = true;
    print('✅ NotiService initialized');
  }

  // ✅ NEW: Explicitly create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return;

    // Main prayer channel (high priority)
    const mainChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'Prayer Reminders',
      description: 'Notifications when prayer time enters',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      // icon: 'ic_prayer', // Add to android/app/src/main/res/drawable/
    );

    // Pre-alert channel (normal priority)
    const preAlertChannel = AndroidNotificationChannel(
      'prayer_prealert_reminders',
      'Prayer Pre-Alerts',
      description: 'Reminders 10 minutes before prayer time',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    // Test channel (for debugging)
    const testChannel = AndroidNotificationChannel(
      'test_notifications',
      'Test Notifications',
      description: 'Channel for testing notification delivery',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImpl.createNotificationChannel(mainChannel);
    await androidImpl.createNotificationChannel(preAlertChannel);
    await androidImpl.createNotificationChannel(testChannel);

    print('🔔 Notification channels created');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+: Request notification permission
      final notificationsGranted =
          await androidImpl?.requestNotificationsPermission();
      print('🔔 Notification permission: $notificationsGranted');

      // Android 14+: Request exact alarm permission (critical for prayer times!)
      final exactAlarmsGranted =
          await androidImpl?.requestExactAlarmsPermission();
      print('⏰ Exact alarms permission: $exactAlarmsGranted');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final prayerName = response.payload;
    print('🔔 Notification tapped: $prayerName');
  }

  // ---------------------------------------------------------------------------
  // Main Scheduling Logic
  // ---------------------------------------------------------------------------
  Future<void> schedulePrayerNotifications(List<MyPrayer> prayers) async {
    print('📅 Scheduling notifications for ${prayers.length} prayers');

    // ✅ Clear previous to avoid duplicates when rescheduling
    await cancelAllPrayerNotifications();

    final now = DateTime.now();
    int scheduledCount = 0;

    for (final prayer in prayers) {
      // Skip if prayer time has already passed today
      if (prayer.time.isBefore(now)) {
        print('⏭️  Skipping ${prayer.name} (already passed)');
        continue;
      }

      // ✅ Schedule main notification (EXACT timing for prayers!)
      await _scheduleSinglePrayer(prayer);
      scheduledCount++;

      // ✅ Schedule pre-alert if enabled
      final preAlertTime = prayer.time.subtract(const Duration(minutes: 10));

      if (preAlertTime.isAfter(now)) {
        await _schedulePreAlert(prayer, preAlertTime);
        scheduledCount++;
        print('⏰ Pre-alert scheduled for ${prayer.name} at $preAlertTime');
      } else {
        print('⏭️  Skipping pre-alert for ${prayer.name} (time passed)');
      }
    }

    print('✅ Scheduled $scheduledCount notifications');
    await debugScheduledNotifications();
  }

  /// Schedule the MAIN prayer notification (exact timing)
  Future<void> _scheduleSinglePrayer(MyPrayer prayer) async {
    final prayerTime = tz.TZDateTime.from(prayer.time, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'prayer_reminders',
      'Prayer Reminders',
      channelDescription: 'Notifications when prayer time enters',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF5E35B1), // Purple accent
      // icon: 'ic_prayer',
    );

    await _plugin.zonedSchedule(
      mainNotificationId(prayer.prayer),
      '🕌 وقت الصلاة: ${prayer.name}',
      'حان وقت صلاة ${prayer.name}',
      prayerTime,
      const NotificationDetails(android: androidDetails),
      // ✅ Critical: Repeat daily at the same time
      matchDateTimeComponents: DateTimeComponents.time,
      // ✅ Use EXACT scheduling for prayer accuracy
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: prayer.prayer.name,
    );

    print('🕌 Scheduled main: ${prayer.name} at $prayerTime');
  }

  /// Schedule the PRE-ALERT notification (10 min before)
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
      color: Color(0xFF1565C0), // Blue accent
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
  // Cancellation Methods
  // ---------------------------------------------------------------------------
  Future<void> cancelAllPrayerNotifications() async {
    await _plugin.cancelAll();
    print('🗑️  Cancelled all prayer notifications');
  }

  Future<void> cancelPrayerNotification(Prayer prayer) async {
    await _plugin.cancel(mainNotificationId(prayer));
    await _plugin.cancel(preAlertNotificationId(prayer));
    print('🗑️  Cancelled notifications for ${prayer.name}');
  }

  // ---------------------------------------------------------------------------
  // Debug & Testing Helpers
  // ---------------------------------------------------------------------------
  /// Show immediate test notification (for debugging)
  Future<void> showTestNotification({
    String title = '🧪 Test',
    String body = 'Notifications are working!',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'test_notifications',
      'Test Notifications',
      channelDescription: 'For testing',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      testNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'test',
    );
    print('🧪 Test notification sent');
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
