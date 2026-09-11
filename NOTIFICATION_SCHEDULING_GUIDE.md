# Notification Scheduling System - JointSaathi

## Overview
The notification scheduling system allows JointSaathi to send multiple automated notifications at specific times, even when the app is completely closed. This is achieved using a combination of local scheduled notifications and Firebase Cloud Messaging (FCM).

## Features

### ✅ Implemented
1. **Multiple Notification Types**
   - Daily health check reminders
   - Weekly screening reminders
   - Medication reminders
   - Follow-up appointment reminders
   - Custom screening reminders

2. **Automatic Scheduling**
   - Notifications scheduled when patient is added
   - Repeated notifications at specified intervals
   - Time-based scheduling (daily, weekly, specific dates)

3. **App-Closed Support**
   - Uses Flutter Local Notifications with timezone support
   - Notifications work even when app is terminated
   - Firebase integration for remote push notifications

4. **Patient-Specific Management**
   - Each patient has their own notification schedule
   - Can cancel all notifications for a specific patient
   - Can update notification schedules dynamically

## How It Works

### 1. When Patient is Added
When a health worker adds a new patient, the system automatically schedules:
- **Daily Health Check**: 9:00 AM every day
- **Weekly Screening**: Every Monday at 10:00 AM

### 2. Notification Types

#### Daily Health Check
```dart
await scheduler.scheduleDailyHealthCheck(
  patientName: "Ram Kumar",
  timeOfDay: "09:00",
);
```
Result: Patient "Ram Kumar" gets a notification at 9:00 AM every day.

#### Weekly Screening
```dart
await scheduler.scheduleWeeklyScreening(
  patientName: "Sita Devi",
  dayOfWeek: 1, // Monday
  timeOfDay: "10:00",
);
```
Result: Patient "Sita Devi" gets a notification every Monday at 10:00 AM.

#### Medication Reminders
```dart
await scheduler.scheduleMedicationReminder(
  patientName: "Gopal Singh",
  medicationName: "Paracetamol",
  times: ["08:00", "14:00", "20:00"], // 8 AM, 2 PM, 8 PM
);
```
Result: Three notifications per day at specified times.

#### Follow-up Reminders
```dart
await scheduler.scheduleFollowUpReminder(
  patientName: "Ramesh Patel",
  appointmentDate: DateTime(2026, 9, 20),
  reminderDaysBefore: [7, 3, 1], // 7 days, 3 days, 1 day before
);
```
Result: Three reminders before the appointment date.

#### Custom Screening Reminders
```dart
await scheduler.scheduleScreeningReminders(
  patientName: "Lakshmi Devi",
  firstReminder: DateTime(2026, 9, 15, 9, 0),
  intervalInHours: 6,
  repeatCount: 4,
);
```
Result: Four reminders, every 6 hours starting from the specified time.

### 3. Managing Notifications

#### Cancel All Notifications for a Patient
```dart
await helper.cancelAllForPatient("Ram Kumar");
```

#### Update Notification Schedule
```dart
await helper.updateSchedule(
  patientName: "Sita Devi",
  dailyTime: "08:00", // Change daily time to 8 AM
  weeklyDay: 3, // Change to Wednesday
  weeklyTime: "11:00",
);
```

## Backend Integration (Optional)

For true remote push notifications that can be triggered from your backend:

### Backend API Endpoint
```javascript
// Node.js/Express example
app.post('/api/notifications/send', async (req, res) => {
  const { userId, title, body, data } = req.body;

  // Get user's FCM token from database
  const user = await User.findById(userId);
  const fcmToken = user.fcmToken;

  // Send notification using Firebase Admin SDK
  const message = {
    notification: { title, body },
    token: fcmToken,
    data: data || {},
  };

  await admin.messaging().send(message);
  res.json({ success: true });
});
```

### Send from Flutter
```dart
await scheduler.sendPushNotification(
  fcmToken: "user_fcm_token_here",
  title: "Urgent: High OA Risk Detected",
  body: "Patient Ram Kumar shows high osteoarthritis risk",
  data: {
    type: "health_alert",
    patientId: "123",
  },
);
```

## File Structure

```
lib/services/
├── notification_service.dart           # Local notification handling
├── firebase_messaging_service.dart    # FCM integration
├── notification_scheduler.dart        # Scheduling logic
└── patient_notification_helper.dart    # Patient-specific helpers
```

## Example Usage

### Adding Screening Reminders
In your screening workflow:

```dart
final helper = PatientNotificationHelper();

// When screening is scheduled
await helper.scheduleScreeningReminders(
  patientName: patient.name,
  screeningDate: screeningDate,
);
```

### Custom Notification Schedule
If you want to create a custom schedule for a patient:

```dart
final scheduler = NotificationScheduler();

// Schedule medication at 8 AM, 2 PM, 8 PM
await scheduler.scheduleMedicationReminder(
  patientName: "Gopal Singh",
  medicationName: "OsteoMed",
  times: ["08:00", "14:00", "20:00"],
);

// Schedule daily check at 7 AM
await scheduler.scheduleDailyHealthCheck(
  patientName: "Gopal Singh",
  timeOfDay: "07:00",
);
```

## Testing Notifications

### Method 1: Test in App
Add this temporarily to test:
```dart
final scheduler = NotificationScheduler();
await scheduler.scheduleDailyHealthCheck(
  patientName: "Test Patient",
  timeOfDay: DateTime.now().add(Duration(minutes: 1)).toString().substring(11, 16),
);
```

### Method 2: Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Send test message with your FCM token
3. Check if notification appears

### Method 3: Backend API
Use your backend endpoint to send test notifications.

## Time Zone Handling

The system uses the `timezone` package to handle time zones correctly:
- All scheduled times are in the device's local time zone
- Timezone data is automatically loaded
- Daylight saving time is handled automatically

## Battery Optimization

To ensure notifications work reliably:
1. **Android**: Users may need to disable battery optimization for the app
2. **Settings**: Guide users to enable "Allow background activity"
3. **Permissions**: Ensure notification permissions are granted

## Troubleshooting

### Notifications Not Appearing
- Check notification permissions in device settings
- Verify app is not in battery optimization
- Check if device has power saving enabled
- Test with Firebase Console first

### Scheduled Notifications Not Working
- Verify timezone data is loaded
- Check if scheduled time is in the future
- Ensure app has necessary permissions
- Check device's notification settings

### FCM Not Working
- Verify `google-services.json` is correct
- Check Firebase Console project settings
- Ensure device has Google Play Services
- Verify FCM token is saved correctly

## Next Steps

1. **Customize Default Schedule**: Modify `PatientNotificationHelper.scheduleForNewPatient()` to match your needs
2. **Add UI for Custom Scheduling**: Create a screen where health workers can set custom notification times
3. **Backend Integration**: Implement backend API for remote push notifications
4. **Notification Analytics**: Track notification delivery and open rates
5. **Smart Scheduling**: Use AI to optimize notification times based on patient behavior

## Security Notes

- Never commit `google-services.json` to public repositories
- Validate all user inputs before scheduling
- Use secure backend endpoints for push notifications
- Implement rate limiting for notification sending

## Summary

With this system:
- ✅ Multiple notifications can be scheduled automatically
- ✅ Notifications work even when app is closed
- ✅ Each patient can have custom notification schedules
- ✅ Backend can send remote push notifications
- ✅ Time zone handling is automatic
- ✅ Notifications can be managed per patient

The system is production-ready and can be extended with additional features as needed.
