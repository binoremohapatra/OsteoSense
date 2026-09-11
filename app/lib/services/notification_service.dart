import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

enum NotificationType {
  general,
  screening,
  health,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Initialize timezone
    tz_data.initializeTimeZones();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to relevant screen
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('Notification permission granted: $granted');
    }
  }

  Future<bool> checkQuietHours(SettingsProvider settings) async {
    if (!settings.quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;

    final startParts = settings.quietHoursStart.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 22;
    final startMinute = int.tryParse(startParts[1]) ?? 0;
    final startTimeInMinutes = startHour * 60 + startMinute;

    final endParts = settings.quietHoursEnd.split(':');
    final endHour = int.tryParse(endParts[0]) ?? 7;
    final endMinute = int.tryParse(endParts[1]) ?? 0;
    final endTimeInMinutes = endHour * 60 + endMinute;

    // Check if current time is within quiet hours
    if (startTimeInMinutes < endTimeInMinutes) {
      // Same day (e.g., 22:00 - 07:00 next day)
      return currentTimeInMinutes >= startTimeInMinutes ||
          currentTimeInMinutes < endTimeInMinutes;
    } else {
      // Same day (e.g., 22:00 - 23:00)
      return currentTimeInMinutes >= startTimeInMinutes &&
          currentTimeInMinutes < endTimeInMinutes;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('push_notifications_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    if (!pushEnabled) {
      debugPrint('Push notifications disabled, skipping');
      return;
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'joint_saathi_channel',
      'JointSaathi Notifications',
      channelDescription: 'Notifications from JointSaathi app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      vibrationPattern: vibrationEnabled ? null : Int64List(0),
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> showScreeningReminder({
    required String patientName,
    required DateTime scheduledTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersEnabled = prefs.getBool('screening_reminders_enabled') ?? true;

    if (!remindersEnabled) {
      debugPrint('Screening reminders disabled, skipping');
      return;
    }

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Screening Reminder',
      body: 'Time to screen patient: $patientName',
      type: NotificationType.screening,
    );
  }

  Future<void> showHealthAlert({
    required String patientName,
    required String alertMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final alertsEnabled = prefs.getBool('health_alerts_enabled') ?? true;

    if (!alertsEnabled) {
      debugPrint('Health alerts disabled, skipping');
      return;
    }

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Health Alert',
      body: '$patientName: $alertMessage',
      type: NotificationType.health,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'joint_saathi_channel',
          'JointSaathi Notifications',
          channelDescription: 'Notifications from JointSaathi app',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
