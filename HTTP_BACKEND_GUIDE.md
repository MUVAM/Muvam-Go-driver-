# Backend HTTP-Based Notification Sending Guide

## Overview
This guide shows how to send push notifications from your backend using **HTTP requests** to Firebase Cloud Messaging (FCM), matching the WorkPal app pattern.

**Important**: Your backend sends notifications via HTTP. The Flutter app only receives and displays them.

---

## Backend Setup (Node.js Example)

### 1. Install Dependencies
```bash
npm install googleapis firebase-admin
```

### 2. Get OAuth Access Token

```javascript
const { google } = require('googleapis');
const serviceAccount = require('./firebase-service-account.json');

async function getAccessToken() {
  const jwtClient = new google.auth.JWT(
    serviceAccount.client_email,
    null,
    serviceAccount.private_key,
    [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ],
    null
  );

  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}
```

### 3. Send Notification via HTTP

```javascript
const axios = require('axios');

async function sendNotification({ deviceToken, title, body, type, additionalData = {} }) {
  try {
    const accessToken = await getAccessToken();
    
    const fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/muvam-go/messages:send';
    
    const message = {
      message: {
        token: deviceToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          vibrate: 'true',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...additionalData,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            channel_id: 'muvam_notifications',
            vibrate_timings: ['0s', '0.5s', '0.25s', '0.5s'],
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: 'default',
            },
          },
        },
      },
    };

    const response = await axios.post(fcmEndpoint, message, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    console.log('✅ Notification sent successfully:', response.data);
    return { success: true, data: response.data };
  } catch (error) {
    console.error('❌ Failed to send notification:', error.response?.data || error.message);
    
    // Handle invalid token
    if (error.response?.status === 400 || error.response?.status === 404) {
      const errorMessage = error.response?.data?.error?.message || '';
      if (errorMessage.includes('not a valid FCM registration token') ||
          errorMessage.includes('Requested entity was not found')) {
        return { success: false, invalidToken: true, token: deviceToken };
      }
    }
    
    return { success: false, error: error.message };
  }
}
```

---

## Notification Functions for All Use Cases

### 1. Ride Accepted Notification

```javascript
async function notifyRideAccepted(passengerId, rideData) {
  // Get passenger's FCM tokens from Firestore
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(passengerId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    const result = await sendNotification({
      deviceToken: token,
      title: 'Ride Accepted! 🚗',
      body: `Your driver ${rideData.driverName} is on the way!`,
      type: 'ride_accepted',
      additionalData: {
        rideId: rideData.rideId.toString(),
        driverName: rideData.driverName,
        driverImage: rideData.driverImage || '',
        vehicleInfo: rideData.vehicleInfo || '',
      },
    });
    
    // Remove invalid tokens
    if (result.invalidToken) {
      await removeInvalidToken(passengerId, token);
    }
  }
}

// Usage
await notifyRideAccepted('passenger_user_id', {
  rideId: 123,
  driverName: 'John Doe',
  driverImage: 'https://...',
  vehicleInfo: 'Toyota Camry - ABC 123',
});
```

### 2. Driver Arrived Notification

```javascript
async function notifyDriverArrived(passengerId, rideId) {
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(passengerId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    await sendNotification({
      deviceToken: token,
      title: 'Driver Has Arrived 📍',
      body: 'Your driver has arrived at the pickup location',
      type: 'driver_arrived',
      additionalData: {
        rideId: rideId.toString(),
      },
    });
  }
}
```

### 3. Ride Started Notification

```javascript
async function notifyRideStarted(passengerId, rideData) {
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(passengerId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    await sendNotification({
      deviceToken: token,
      title: 'Ride Started 🚀',
      body: 'Your ride has started. Enjoy your trip!',
      type: 'ride_started',
      additionalData: {
        rideId: rideData.rideId.toString(),
        destination: rideData.destination || '',
      },
    });
  }
}
```

### 4. Ride Completed Notification

```javascript
async function notifyRideCompleted(passengerId, rideData) {
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(passengerId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    await sendNotification({
      deviceToken: token,
      title: 'Ride Completed ✅',
      body: 'Your ride is complete. Thank you for using Muvam!',
      type: 'ride_completed',
      additionalData: {
        rideId: rideData.rideId.toString(),
        fare: rideData.fare.toString(),
      },
    });
  }
}
```

### 5. New Message Notification

```javascript
async function notifyNewMessage(recipientId, messageData) {
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(recipientId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    await sendNotification({
      deviceToken: token,
      title: 'New Message 💬',
      body: messageData.message.substring(0, 100),
      type: 'new_message',
      additionalData: {
        rideId: messageData.rideId.toString(),
        message: messageData.message,
        senderName: messageData.senderName,
        senderId: messageData.senderId.toString(),
      },
    });
  }
}
```

### 6. Incoming Call Notification

```javascript
async function notifyIncomingCall(recipientId, callData) {
  const tokensDoc = await admin.firestore()
    .collection('users')
    .doc(recipientId)
    .collection('tokens')
    .doc('fcm_tokens')
    .get();
  
  const tokens = tokensDoc.data()?.tokens || [];
  
  for (const token of tokens) {
    await sendNotification({
      deviceToken: token,
      title: 'Incoming Call 📞',
      body: `${callData.callerName} is calling...`,
      type: 'incoming_call',
      additionalData: {
        sessionId: callData.sessionId,
        callerName: callData.callerName,
        rideId: callData.rideId.toString(),
      },
    });
  }
}
```

---

## Helper Functions

### Remove Invalid Token

```javascript
async function removeInvalidToken(userId, invalidToken) {
  const tokenRef = admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('tokens')
    .doc('fcm_tokens');
  
  const doc = await tokenRef.get();
  if (doc.exists) {
    const tokens = doc.data().tokens || [];
    const updatedTokens = tokens.filter(t => t !== invalidToken);
    
    await tokenRef.update({
      tokens: updatedTokens,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`🗑️ Removed invalid token for user ${userId}`);
  }
}
```

---

## Complete Express.js API Example

```javascript
const express = require('express');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const axios = require('axios');

const serviceAccount = require('./firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(express.json());

// Get OAuth access token
async function getAccessToken() {
  const jwtClient = new google.auth.JWT(
    serviceAccount.client_email,
    null,
    serviceAccount.private_key,
    [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ],
    null
  );

  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}

// Send notification via HTTP
async function sendNotification({ deviceToken, title, body, type, additionalData = {} }) {
  const accessToken = await getAccessToken();
  const fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/muvam-go/messages:send';
  
  const message = {
    message: {
      token: deviceToken,
      notification: { title, body },
      data: {
        type,
        vibrate: 'true',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...additionalData,
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          channel_id: 'muvam_notifications',
          vibrate_timings: ['0s', '0.5s', '0.25s', '0.5s'],
        },
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            badge: 1,
            sound: 'default',
          },
        },
      },
    },
  };

  const response = await axios.post(fcmEndpoint, message, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  return response.data;
}

// API Endpoints
app.post('/api/notifications/ride-accepted', async (req, res) => {
  try {
    const { passengerId, rideId, driverName } = req.body;
    
    const tokensDoc = await admin.firestore()
      .collection('users')
      .doc(passengerId)
      .collection('tokens')
      .doc('fcm_tokens')
      .get();
    
    const tokens = tokensDoc.data()?.tokens || [];
    
    for (const token of tokens) {
      await sendNotification({
        deviceToken: token,
        title: 'Ride Accepted! 🚗',
        body: `Your driver ${driverName} is on the way!`,
        type: 'ride_accepted',
        additionalData: { rideId: rideId.toString(), driverName },
      });
    }
    
    res.json({ success: true, sentTo: tokens.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add more endpoints for other notification types...

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Notification server running on port ${PORT}`);
});
```

---

## Testing

### Test with cURL

```bash
curl -X POST http://localhost:3000/api/notifications/ride-accepted \
  -H "Content-Type: application/json" \
  -d '{
    "passengerId": "user_123",
    "rideId": 456,
    "driverName": "John Doe"
  }'
```

---

## Firestore Structure

```
users/
  └── {userId}/
      └── tokens/
          └── fcm_tokens/
              ├── tokens: ["token1", "token2", ...]
              └── lastUpdated: timestamp
```

---

**Last Updated:** December 31, 2025  
**Pattern:** HTTP-based (like WorkPal)
