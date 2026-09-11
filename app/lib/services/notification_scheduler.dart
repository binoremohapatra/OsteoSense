import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationService _notificationService = NotificationService();

  // Schedule screening reminders
  Future<void> scheduleScreeningReminders({
    required String patientName,
    required DateTime firstReminder,
    required int intervalInHours,
    required int repeatCount,
  }) async {
    for (int i = 0; i < repeatCount; i++) {
      final scheduledTime = firstReminder.add(Duration(hours: i * intervalInHours));
      final notificationId = _generateNotificationId('screening', patientName, i);

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Screening Reminder',
        body: 'Time to screen patient: $patientName',
        scheduledDate: scheduledTime,
        payload: 'screening:$patientName:$i',
      );

      debugPrint('Scheduled screening reminder #$i for $patientName at $scheduledTime');
    }
  }

  // Schedule daily health check reminders
  Future<void> scheduleDailyHealthCheck({
    required String patientName,
    required String timeOfDay, // Format: "HH:MM"
  }) async {
    final now = DateTime.now();
    final parts = timeOfDay.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final notificationId = _generateNotificationId('daily', patientName, 0);

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Daily Health Check',
      body: 'Remember to check on patient: $patientName',
      scheduledDate: scheduledTime,
      payload: 'daily:$patientName',
    );

    debugPrint('Scheduled daily health check for $patientName at $timeOfDay');
  }

  // Schedule weekly screening reminders
  Future<void> scheduleWeeklyScreening({
    required String patientName,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required String timeOfDay,
  }) async {
    final now = DateTime.now();
    final parts = timeOfDay.split(':');
    final hour = int.tryParse(parts[0]) ?? 10;
    final minute = int.tryParse(parts[1]) ?? 0;

    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Find the next occurrence of the specified day
    while (scheduledTime.weekday != dayOfWeek) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // If time has passed today, schedule for next week
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    final notificationId = _generateNotificationId('weekly', patientName, 0);

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Weekly Screening',
      body: 'Weekly screening due for: $patientName',
      scheduledDate: scheduledTime,
      payload: 'weekly:$patientName',
    );

    debugPrint('Scheduled weekly screening for $patientName on day $dayOfWeek at $timeOfDay');
  }

  // Schedule medication reminders
  Future<void> scheduleMedicationReminder({
    required String patientName,
    required String medicationName,
    required List<String> times, // List of "HH:MM" strings
  }) async {
    final now = DateTime.now();

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final notificationId = _generateNotificationId('medication', patientName, i);

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Medication Reminder',
        body: '$medicationName due for: $patientName',
        scheduledDate: scheduledTime,
        payload: 'medication:$patientName:$medicationName:$i',
      );

      debugPrint('Scheduled medication reminder #$i for $patientName at ${times[i]}');
    }
  }

  // Schedule follow-up appointment reminders
  Future<void> scheduleFollowUpReminder({
    required String patientName,
    required DateTime appointmentDate,
    required List<int> reminderDaysBefore, // e.g., [7, 3, 1] for 7 days, 3 days, 1 day before
  }) async {
    for (int i = 0; i < reminderDaysBefore.length; i++) {
      final reminderDate = appointmentDate.subtract(
        Duration(days: reminderDaysBefore[i]),
      );

      final notificationId = _generateNotificationId('followup', patientName, i);

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Follow-up Reminder',
        body: 'Follow-up appointment for $patientName in ${reminderDaysBefore[i]} days',
        scheduledDate: reminderDate,
        payload: 'followup:$patientName:$i',
      );

      debugPrint('Scheduled follow-up reminder #$i for $patientName at $reminderDate');
    }
  }

  // Cancel all notifications for a patient
  Future<void> cancelPatientNotifications(String patientName) async {
    final prefs = await SharedPreferences.getInstance();
    final patientNotificationIds = prefs.getStringList('notifications_$patientName') ?? [];

    for (final id in patientNotificationIds) {
      final notificationId = int.tryParse(id);
      if (notificationId != null) {
        await _notificationService.cancelNotification(notificationId);
      }
    }

    await prefs.remove('notifications_$patientName');
    debugPrint('Cancelled all notifications for $patientName');
  }

  // Cancel specific notification type for a patient
  Future<void> cancelNotificationType({
    required String patientName,
    required String type, // 'screening', 'daily', 'weekly', 'medication', 'followup'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = prefs.getStringList('notifications_$patientName') ?? [];

    for (final id in allIds) {
      if (id.startsWith('$type:')) {
        final notificationId = int.tryParse(id.split(':')[1]);
        if (notificationId != null) {
          await _notificationService.cancelNotification(notificationId);
        }
      }
    }

    debugPrint('Cancelled $type notifications for $patientName');
  }

  // Generate unique notification ID
  int _generateNotificationId(String type, String patientName, int index) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = '$type:$patientName:$index:$timestamp'.hashCode;
    return hash.abs();
  }

  // Send immediate push notification via FCM (requires backend)
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // This would typically call your backend API
    // Backend then uses Firebase Admin SDK to send the notification
    debugPrint('Push notification requested for token: $fcmToken');
    debugPrint('Title: $title, Body: $body');

    // TODO: Call backend API
    // await _apiService.sendPushNotification(
    //   fcmToken: fcmToken,
    //   title: title,
    //   body: body,
    //   data: data,
    // );
  }

  // Get scheduled notifications count
  Future<int> getScheduledCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }
}
