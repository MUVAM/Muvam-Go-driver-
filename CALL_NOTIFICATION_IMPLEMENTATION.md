# Call Notification Action Buttons Implementation Guide

## Overview
This document explains how to add Accept and Reject action buttons to incoming call notifications in the Muvam Rider app.

## What Was Implemented

### 1. Call Notification Helper Service
**File**: `lib/core/services/call_notification_helper.dart`

This service handles:
- Creating a dedicated notification channel for incoming calls
- Showing notifications with Accept/Reject action buttons
- Handling user responses (accept/reject)
- Storing pending call actions for the app to process

### 2. Call Notification Service  
**File**: `lib/core/services/call_notification_helper.dart`

Sends FCM notifications with proper configuration for call notifications.

## How It Works

### When a Call Comes In:

1. **FCM Notification Sent**: The server sends an FCM notification with call data
2. **Local Notification Shown**: The app receives it and shows a local notification with action buttons
3. **User Interaction**: User can:
   - Tap "Accept" → Opens app and navigates to call screen
   - Tap "Reject" → Dismisses notification
   - Tap notification body → Opens app to call screen

### Implementation Steps Needed:

#### Step 1: Initialize Call Notification Handler

In your `main.dart` or app initialization:

```dart
import 'package:muvam_rider/core/services/call_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize call notification handler
  await CallNotificationHandler.initialize();
  
  runApp(MyApp());
}
```

#### Step 2: Handle Incoming Call Notifications

In your FCM message handler (usually in `fcm_notification_service.dart`):

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  // Check if this is a call notification
  if (message.data['type'] == 'incoming_call') {
    // Show local notification with action buttons
    await CallNotificationHandler.showIncomingCallNotification(
      callerName: message.data['caller_name'] ?? 'Unknown',
      callerImage: message.data['caller_image'] ?? '',
      rideId: message.data['ride_id'] ?? '',
      sessionId: message.data['session_id'] ?? '',
    );
    return; // Don't show default notification
  }
  
  // Handle other notifications normally
  // ... existing code
});
```

#### Step 3: Check for Pending Call Actions

In your app's main screen or home screen, check for pending call actions:

```dart
@override
void initState() {
  super.initState();
  _checkPendingCallAction();
}

Future<void> _checkPendingCallAction() async {
  final callAction = CallNotificationHandler.getPendingCallAction();
  if (callAction != null && callAction['action'] == 'accept') {
    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          driverName: callAction['caller_name'],
          rideId: int.parse(callAction['ride_id']),
        ),
      ),
    );
  }
}
```

## Required Assets

You need to add these drawable resources to your Android project:

**Location**: `android/app/src/main/res/drawable/`

1. `ic_call.xml` - Accept call icon
2. `ic_call_end.xml` - Reject call icon  
3. `ic_notification.xml` - Default notification icon

Example `ic_call.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#4CAF50"
        android:pathData="M6.62,10.79c1.44,2.83 3.76,5.14 6.59,6.59l2.2,-2.2c0.27,-0.27 0.67,-0.36 1.02,-0.24 1.12,0.37 2.33,0.57 3.57,0.57 0.55,0 1,0.45 1,1V20c0,0.55 -0.45,1 -1,1 -9.39,0 -17,-7.61 -17,-17 0,-0.55 0.45,-1 1,-1h3.5c0.55,0 1,0.45 1,1 0,1.25 0.2,2.45 0.57,3.57 0.11,0.35 0.03,0.74 -0.25,1.02l-2.2,2.2z"/>
</vector>
```

Example `ic_call_end.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#F44336"
        android:pathData="M12,9c-1.6,0 -3.15,0.25 -4.6,0.72v3.1c0,0.39 -0.23,0.74 -0.56,0.9 -0.98,0.49 -1.87,1.12 -2.66,1.85 -0.18,0.18 -0.43,0.28 -0.7,0.28 -0.28,0 -0.53,-0.11 -0.71,-0.29L0.29,13.08c-0.18,-0.17 -0.29,-0.42 -0.29,-0.7 0,-0.28 0.11,-0.53 0.29,-0.71C3.34,8.78 7.46,7 12,7s8.66,1.78 11.71,4.67c0.18,0.18 0.29,0.43 0.29,0.71 0,0.28 -0.11,0.53 -0.29,0.71l-2.48,2.48c-0.18,0.18 -0.43,0.29 -0.71,0.29 -0.27,0 -0.52,-0.11 -0.7,-0.28 -0.79,-0.74 -1.69,-1.36 -2.67,-1.85 -0.33,-0.16 -0.56,-0.5 -0.56,-0.9v-3.1C15.15,9.25 13.6,9 12,9z"/>
</vector>
```

## Optional: Ringtone Sound

Add a custom ringtone:

**Location**: `android/app/src/main/res/raw/ringtone.mp3`

This will play when the call notification appears.

## Testing

1. Send a call notification from your backend/driver app
2. Notification should appear with "Accept" and "Reject" buttons
3. Tapping "Accept" should open the app and navigate to call screen
4. Tapping "Reject" should dismiss the notification

## Current Status

✅ Created call notification handler service
✅ Created FCM call notification sender
✅ Added action button support
⚠️ Needs integration into existing FCM handler
⚠️ Needs drawable resources added
⚠️ Needs testing

## Next Steps

1. Add the drawable resources (ic_call.xml, ic_call_end.xml)
2. Initialize CallNotificationHandler in main.dart
3. Update FCM onMessage handler to use CallNotificationHandler for call notifications
4. Add pending call action check in home screen
5. Test with real call notifications

## Notes

- The notification will show as a heads-up notification on Android
- On iOS, you'll need to configure UNNotificationCategory for action buttons
- Make sure to handle permissions for notifications
- The notification is "ongoing" and won't auto-dismiss until user interacts with it
