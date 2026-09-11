import 'package:flutter/foundation.dart';
import 'notification_scheduler.dart';

class PatientNotificationHelper {
  static final PatientNotificationHelper _instance =
      PatientNotificationHelper._internal();
  factory PatientNotificationHelper() => _instance;
  PatientNotificationHelper._internal();

  final NotificationScheduler _scheduler = NotificationScheduler();

  // Schedule notifications when a new patient is added
  Future<void> scheduleForNewPatient({
    required String patientName,
    required String patientId,
  }) async {
    try {
      // Schedule daily health check at 9 AM
      await _scheduler.scheduleDailyHealthCheck(
        patientName: patientName,
        timeOfDay: '09:00',
      );

      // Schedule weekly screening on Monday (day 1)
      await _scheduler.scheduleWeeklyScreening(
        patientName: patientName,
        dayOfWeek: 1, // Monday
        timeOfDay: '10:00',
      );

      debugPrint('Scheduled default notifications for new patient: $patientName');
    } catch (e) {
      debugPrint('Error scheduling notifications for new patient: $e');
    }
  }

  // Schedule screening reminders
  Future<void> scheduleScreeningReminders({
    required String patientName,
    required DateTime screeningDate,
  }) async {
    try {
      // Schedule reminder 1 day before
      await _scheduler.scheduleFollowUpReminder(
        patientName: patientName,
        appointmentDate: screeningDate,
        reminderDaysBefore: [1],
      );

      // Schedule reminder on the day
      await _scheduler.scheduleScreeningReminders(
        patientName: patientName,
        firstReminder: screeningDate.subtract(const Duration(hours: 2)),
        intervalInHours: 1,
        repeatCount: 2,
      );

      debugPrint('Scheduled screening reminders for: $patientName');
    } catch (e) {
      debugPrint('Error scheduling screening reminders: $e');
    }
  }

  // Schedule medication reminders
  Future<void> scheduleMedicationReminders({
    required String patientName,
    required List<String> medicationTimes,
  }) async {
    try {
      await _scheduler.scheduleMedicationReminder(
        patientName: patientName,
        medicationName: 'Prescribed Medication',
        times: medicationTimes,
      );

      debugPrint('Scheduled medication reminders for: $patientName');
    } catch (e) {
      debugPrint('Error scheduling medication reminders: $e');
    }
  }

  // Cancel all notifications for a patient
  Future<void> cancelAllForPatient(String patientName) async {
    try {
      await _scheduler.cancelPatientNotifications(patientName);
      debugPrint('Cancelled all notifications for: $patientName');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // Update notification schedule for a patient
  Future<void> updateSchedule({
    required String patientName,
    String? dailyTime,
    int? weeklyDay,
    String? weeklyTime,
  }) async {
    try {
      // Cancel existing notifications
      await cancelAllForPatient(patientName);

      // Reschedule with new times
      if (dailyTime != null) {
        await _scheduler.scheduleDailyHealthCheck(
          patientName: patientName,
          timeOfDay: dailyTime,
        );
      }

      if (weeklyDay != null && weeklyTime != null) {
        await _scheduler.scheduleWeeklyScreening(
          patientName: patientName,
          dayOfWeek: weeklyDay,
          timeOfDay: weeklyTime,
        );
      }

      debugPrint('Updated notification schedule for: $patientName');
    } catch (e) {
      debugPrint('Error updating notification schedule: $e');
    }
  }
}
