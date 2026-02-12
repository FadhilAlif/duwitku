import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationTemplate {
  final String title;
  final String body;
  final String emoji;

  const NotificationTemplate({
    required this.title,
    required this.body,
    required this.emoji,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _keyEnabled = 'notification_enabled';
  static const String _keyHour = 'notification_hour';
  static const String _keyMinute = 'notification_minute';
  static const String _keyTemplateIndex = 'notification_template_index';

  static const List<NotificationTemplate> templates = [
    NotificationTemplate(
      title: 'Catat Transaksimu!',
      body: 'Jangan lupa catat pengeluaranmu hari ini 📝',
      emoji: '📝',
    ),
    NotificationTemplate(
      title: 'Hati-hati Pengeluaran!',
      body: 'Hati-hati, pengeluaranmu sudah banyak bulan ini! 💸',
      emoji: '💸',
    ),
    NotificationTemplate(
      title: 'Yuk Cek Keuanganmu',
      body: 'Luangkan waktu untuk review keuanganmu hari ini 📊',
      emoji: '📊',
    ),
    NotificationTemplate(
      title: 'Pengingat Menabung',
      body: 'Sudah menabung hari ini? Yuk sisihkan sedikit 💰',
      emoji: '💰',
    ),
    NotificationTemplate(
      title: 'Pantau Budgetmu',
      body: 'Cek apakah budget bulananmu masih on track 🎯',
      emoji: '🎯',
    ),
  ];

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS handles permission via DarwinInitializationSettings
  }

  Future<void> scheduleDailyNotification({
    required TimeOfDay time,
    required NotificationTemplate template,
  }) async {
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'duwitku_daily_reminder',
      'Pengingat Harian',
      channelDescription: 'Notifikasi pengingat harian dari Duwitku',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: 0,
      title: template.title,
      body: template.body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── SharedPreferences helpers ──

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyHour) ?? 20;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveScheduledTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
  }

  Future<int> getSelectedTemplateIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTemplateIndex) ?? 0;
  }

  Future<void> saveSelectedTemplateIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTemplateIndex, index);
  }

  /// Load all settings and re-schedule if enabled
  Future<void> rescheduleIfEnabled() async {
    final enabled = await isEnabled();
    if (enabled) {
      final time = await getScheduledTime();
      final index = await getSelectedTemplateIndex();
      final template = templates[index];
      await scheduleDailyNotification(time: time, template: template);
    }
  }
}
