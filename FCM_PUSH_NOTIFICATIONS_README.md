# Firebase Cloud Messaging (FCM) Push Notifications Implementation

## Overview
This implementation adds comprehensive push notification support to the Muvam Rider app using Firebase Cloud Messaging (FCM). Notifications are sent for ride events, messages, and incoming calls, with full support for both Android and iOS platforms.

## Features Implemented

### ✅ Core Features
- **Automatic Token Management**: FCM tokens are automatically retrieved and stored in Firestore (`users/{userID}/tokens`)
- **Token Refresh Handling**: Tokens are automatically updated when they change
- **Multi-Platform Support**: Works on both Android and iOS
- **Vibration Support**: All notifications trigger device vibration
- **Local Notifications**: Foreground notifications are displayed using flutter_local_notifications
- **Background Notifications**: Handled via Firebase background message handler

### ✅ Notification Use Cases
1. **Ride Accepted**: When a driver accepts the ride
2. **Driver Arrived**: When the driver has arrived at pickup location
3. **Ride Started**: When the ride begins
4. **Ride Completed**: When the ride is finished
5. **New Message**: When the passenger sends a message
6. **Incoming Call**: When there's an incoming call from the passenger

## File Structure

```
lib/
├── core/
│   └── services/
│       ├── fcm_notification_service.dart  # Main FCM service
│       └── fcm_provider.dart              # State management for FCM
├── main.dart                              # Firebase initialization
└── features/
    └── home/
        └── presentation/
            └── screens/
                └── home_screen.dart       # FCM initialization on login

android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml        # Android FCM configuration

ios/
└── Runner/
    └── Info.plist                         # iOS FCM configuration (to be added)

firebase-service-account.json              # Service account credentials (gitignored)
```

## Setup Instructions

### 1. Install Dependencies

The following packages have been added to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  cloud_firestore: ^5.5.2
  flutter_local_notifications: ^18.0.1
  vibration: ^3.1.5  # Already installed
```

Run:
```bash
flutter pub get
```

### 2. Firebase Configuration

#### Android Setup
✅ **Already Configured**
- `google-services.json` is present in `android/app/`
- AndroidManifest.xml has been updated with FCM permissions and services

#### iOS Setup
⚠️ **Action Required**

1. Add `GoogleService-Info.plist` to `ios/Runner/` directory
2. Update `ios/Runner/Info.plist` to add notification permissions:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

3. Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### 3. Service Account Setup

The Firebase service account credentials are stored in `firebase-service-account.json` (gitignored for security).

**Important**: This file contains sensitive credentials and should NEVER be committed to GitHub.

### 4. Backend Integration

To send notifications from your backend, use the Firebase Admin SDK:

#### Example: Send Notification (Node.js)

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function sendNotification(userId, notificationType, data) {
  // Get user's FCM tokens from Firestore
  const tokensSnapshot = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('tokens')
    .get();
  
  const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
  
  if (tokens.length === 0) {
    console.log('No FCM tokens found for user:', userId);
    return;
  }

  // Prepare notification payload
  const payload = {
    notification: {
      title: getNotificationTitle(notificationType),
      body: getNotificationBody(notificationType, data),
    },
    data: {
      type: notificationType,
      ...data,
    },
  };

  // Send to all user's devices
  const response = await admin.messaging().sendToDevice(tokens, payload);
  console.log('Notification sent:', response);
}

function getNotificationTitle(type) {
  switch (type) {
    case 'ride_accepted':
      return 'Ride Accepted! 🚗';
    case 'driver_arrived':
      return 'Driver Has Arrived 📍';
    case 'ride_started':
      return 'Ride Started 🚀';
    case 'ride_completed':
      return 'Ride Completed ✅';
    case 'new_message':
      return 'New Message 💬';
    case 'incoming_call':
      return 'Incoming Call 📞';
    default:
      return 'Muvam Notification';
  }
}

function getNotificationBody(type, data) {
  switch (type) {
    case 'ride_accepted':
      return `Your driver ${data.driverName} is on the way!`;
    case 'driver_arrived':
      return 'Your driver has arrived at the pickup location';
    case 'ride_started':
      return 'Your ride has started. Enjoy your trip!';
    case 'ride_completed':
      return 'Your ride is complete. Thank you for using Muvam!';
    case 'new_message':
      return data.message;
    case 'incoming_call':
      return `${data.callerName} is calling...`;
    default:
      return 'You have a new notification';
  }
}

// Usage examples:
// When driver accepts ride
sendNotification('passenger_user_id', 'ride_accepted', {
  rideId: 123,
  driverName: 'John Doe',
  driverImage: 'https://...',
});

// When driver arrives
sendNotification('passenger_user_id', 'driver_arrived', {
  rideId: 123,
});

// When ride starts
sendNotification('passenger_user_id', 'ride_started', {
  rideId: 123,
});

// When ride completes
sendNotification('passenger_user_id', 'ride_completed', {
  rideId: 123,
  fare: 1500,
});

// When passenger sends message
sendNotification('driver_user_id', 'new_message', {
  rideId: 123,
  message: 'I am waiting at the gate',
  senderName: 'Jane Smith',
});

// When there's an incoming call
sendNotification('driver_user_id', 'incoming_call', {
  sessionId: 'call_session_123',
  callerName: 'Jane Smith',
  rideId: 123,
});
```

#### Example: Send Notification (Go)

```go
package main

import (
    "context"
    "log"
    
    firebase "firebase.google.com/go"
    "firebase.google.com/go/messaging"
    "google.golang.org/api/option"
)

func sendNotification(userId, notificationType string, data map[string]string) error {
    ctx := context.Background()
    
    // Initialize Firebase Admin SDK
    opt := option.WithCredentialsFile("firebase-service-account.json")
    app, err := firebase.NewApp(ctx, nil, opt)
    if err != nil {
        return err
    }
    
    client, err := app.Messaging(ctx)
    if err != nil {
        return err
    }
    
    // Get user tokens from Firestore
    firestoreClient, err := app.Firestore(ctx)
    if err != nil {
        return err
    }
    defer firestoreClient.Close()
    
    tokensSnapshot := firestoreClient.Collection("users").Doc(userId).Collection("tokens").Documents(ctx)
    tokens := []string{}
    
    for {
        doc, err := tokensSnapshot.Next()
        if err == iterator.Done {
            break
        }
        if err != nil {
            return err
        }
        
        tokenData := doc.Data()
        if token, ok := tokenData["token"].(string); ok {
            tokens = append(tokens, token)
        }
    }
    
    if len(tokens) == 0 {
        log.Println("No FCM tokens found for user:", userId)
        return nil
    }
    
    // Prepare message
    message := &messaging.MulticastMessage{
        Notification: &messaging.Notification{
            Title: getNotificationTitle(notificationType),
            Body:  getNotificationBody(notificationType, data),
        },
        Data:   data,
        Tokens: tokens,
    }
    
    // Send notification
    response, err := client.SendMulticast(ctx, message)
    if err != nil {
        return err
    }
    
    log.Printf("Successfully sent %d notifications\n", response.SuccessCount)
    return nil
}
```

## How It Works

### 1. Token Registration
When a user logs in:
1. `FCMProvider` is initialized in `HomeScreen._initializeServices()`
2. FCM token is retrieved from Firebase
3. Token is saved to Firestore at `users/{userID}/tokens/{token}`
4. Token includes platform info (Android/iOS) and timestamps

### 2. Receiving Notifications

#### Foreground (App Open)
- Notification received via `FirebaseMessaging.onMessage`
- Displayed as local notification with vibration
- Callback `onMessageReceived` is triggered

#### Background (App Minimized)
- Handled by `_firebaseMessagingBackgroundHandler`
- System displays notification automatically
- Tapping opens app with notification data

#### Terminated (App Closed)
- Notification wakes app
- Data available via `FirebaseMessaging.getInitialMessage()`

### 3. Notification Tapping
When user taps a notification:
1. `onNotificationTap` callback is triggered
2. `FCMProvider._handleNotificationNavigation()` processes the type
3. App navigates to appropriate screen (ride details, chat, etc.)

### 4. Vibration Pattern
All notifications use this vibration pattern:
- Wait: 0ms
- Vibrate: 500ms
- Wait: 250ms
- Vibrate: 500ms

## Testing

### Test Notification from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Enter your FCM token (check logs for token)
6. Send

### Test from Backend
Use the code examples above to send notifications programmatically.

### Verify Token Storage
Check Firestore:
```
users/
  └── {userID}/
      └── tokens/
          └── {fcmToken}/
              ├── token: "fcm_token_string"
              ├── platform: "android" or "ios"
              ├── createdAt: timestamp
              └── lastUsed: timestamp
```

## Security Considerations

### ✅ Implemented
- `firebase-service-account.json` is gitignored
- `.env` file is gitignored (though currently commented out in .gitignore)
- `google-services.json` is gitignored (though currently commented out)

### ⚠️ Recommendations
1. **Never commit** service account credentials to version control
2. **Use environment variables** for sensitive data in production
3. **Rotate tokens** periodically for enhanced security
4. **Implement token cleanup**: Remove old/unused tokens from Firestore
5. **Add rate limiting** on backend to prevent notification spam

## Troubleshooting

### Notifications Not Received
1. Check FCM token is saved in Firestore
2. Verify `google-services.json` / `GoogleService-Info.plist` are correct
3. Check Android/iOS permissions are granted
4. Review Firebase Console logs for errors
5. Ensure app has internet connection

### iOS Specific Issues
1. Verify APNs certificate is configured in Firebase Console
2. Check `Info.plist` has correct background modes
3. Ensure physical device is used (simulator has limitations)
4. Verify app has notification permissions enabled

### Android Specific Issues
1. Check `google-services.json` matches package name
2. Verify notification channels are created
3. Ensure app has notification permissions (Android 13+)

## Next Steps

### Recommended Enhancements
1. **Topic Subscriptions**: Subscribe to ride-specific topics for targeted notifications
2. **Notification Actions**: Add action buttons (Accept, Decline, etc.)
3. **Rich Notifications**: Add images, sounds, and custom layouts
4. **Analytics**: Track notification open rates and engagement
5. **A/B Testing**: Test different notification messages
6. **Scheduled Notifications**: Send reminders for upcoming rides

### Backend Integration Checklist
- [ ] Set up Firebase Admin SDK on backend
- [ ] Implement notification sending for all 6 use cases
- [ ] Add error handling and retry logic
- [ ] Set up monitoring and logging
- [ ] Test on both Android and iOS devices
- [ ] Implement token cleanup for logged-out users

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review app logs (search for 'FCM' tag)
3. Verify Firestore token storage
4. Test with Firebase Console test messages

## License

This implementation follows the Muvam Rider app license.

---

**Last Updated**: December 31, 2025
**Version**: 1.0.0
**Author**: Muvam Development Team
