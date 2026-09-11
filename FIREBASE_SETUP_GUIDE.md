# Firebase Cloud Messaging (FCM) Setup Guide

## Overview
This guide will help you set up Firebase Cloud Messaging for JointSaathi to enable true push notifications (notifications that work even when the app is completely closed).

## Prerequisites
- Google account
- Firebase Console access
- JointSaathi app package name: `com.example.joint_saathi`

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `JointSaathi-OsteoSense`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the gear icon → Project settings
2. Click "Add app" → Android icon
3. Enter package name: `com.example.joint_saathi`
4. (Optional) App nickname: `JointSaathi Android`
5. (Optional) Debug signing certificate fingerprint - run this command:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. Click "Register app"

## Step 3: Download google-services.json

1. Download `google-services.json` file from Firebase Console
2. Place it in: `D:\OsteoSense\app\android\app\google-services.json`

**Important:** This file contains your Firebase configuration. Never commit it to public repositories!

## Step 4: Verify Android Configuration

The following files have already been configured:

### android/build.gradle.kts
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

### android/app/build.gradle.kts
```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

## Step 5: Run the App

1. Run `flutter pub get` (already done)
2. Run `flutter run`
3. The app will initialize Firebase automatically
4. Check console for FCM token output

## Step 6: Backend Integration

### Backend API Endpoint to Save FCM Token

Create an endpoint to receive and store FCM tokens:

```javascript
// Example Node.js/Express endpoint
app.post('/api/user/fcm-token', async (req, res) => {
  const { userId, fcmToken } = req.body;

  try {
    // Save token to database
    await User.findByIdAndUpdate(userId, { fcmToken });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

### Send Push Notification from Backend

```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
async function sendPushNotification(userFcmToken, title, body) {
  const message = {
    notification: {
      title: title,
      body: body
    },
    token: userFcmToken,
    data: {
      type: 'screening_reminder',
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    }
  };

  try {
    await admin.messaging().send(message);
    console.log('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}
```

## Step 7: Topics (Optional)

You can subscribe users to topics for group notifications:

```dart
// In your Flutter code
final firebaseMessagingService = FirebaseMessagingService();

// Subscribe to screening reminders
await firebaseMessagingService.subscribeToTopic('screening_reminders');

// Subscribe to health alerts
await firebaseMessagingService.subscribeToTopic('health_alerts');
```

Backend can then send to all users subscribed to a topic:

```javascript
const message = {
  notification: {
    title: 'Screening Reminder',
    body: 'Time to screen your patients'
  },
  topic: 'screening_reminders'
};
```

## Testing Notifications

### Method 1: Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Target: Either "User segment" or specific FCM token
5. Click "Send test message" → Enter FCM token from app logs
6. Click "Review" → "Send"

### Method 2: Backend API
Use the backend endpoint to send notifications programmatically.

## Implementation Status

✅ **Completed:**
- Firebase packages added (`firebase_core`, `firebase_messaging`)
- Android Gradle files configured
- FirebaseMessagingService created
- Integration with local notification service
- Token refresh handling
- Foreground/background message handling

⚠️ **Required Actions:**
1. Create Firebase project
2. Download `google-services.json` and place in `android/app/`
3. Create backend endpoint to save FCM tokens
4. Set up Firebase Admin SDK on backend
5. Test notifications

## How It Works

1. **App Initialization:** FirebaseMessagingService initializes on app start
2. **Token Generation:** Firebase generates unique FCM token for device
3. **Token Storage:** Token saved to SharedPreferences and sent to backend
4. **Token Refresh:** If token changes, new token automatically saved
5. **Push Reception:** Backend sends message → Firebase delivers to device
6. **Notification Display:** Local notification service displays message

## Notification Types

### 1. Screening Reminders
- Target specific user or topic `screening_reminders`
- Example: "Time to screen patient: Ram Kumar"

### 2. Health Alerts
- Target specific user or topic `health_alerts`
- Example: "High OA risk detected for patient: Sita Devi"

### 3. System Notifications
- Target all users or specific segments
- Example: "App update available", "New features added"

## Troubleshooting

### No FCM Token Generated
- Check internet connection
- Verify `google-services.json` is in correct location
- Check Firebase Console project settings

### Notifications Not Received
- Verify Android device has Google Play Services
- Check notification permissions in app settings
- Test with Firebase Console first
- Check backend API logs

### Background Messages Not Working
- Ensure background message handler is registered in `main.dart`
- Check if device has power saving enabled
- Verify Android battery optimization settings

## Security Notes

- Never commit `google-services.json` to public repo
- Use environment variables for Firebase Admin SDK credentials on backend
- Validate FCM tokens before storing
- Implement proper authentication on notification endpoints

## Next Steps

After completing setup:
1. Test notifications with Firebase Console
2. Implement backend endpoints
3. Integrate with patient screening workflow
4. Add notification scheduling for reminders
5. Implement notification analytics
