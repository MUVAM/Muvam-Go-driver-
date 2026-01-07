# Backend Integration Guide - FCM Push Notifications

## Overview
This guide provides complete backend integration examples for sending push notifications to the Muvam Rider app using Firebase Cloud Messaging (FCM).

---

## Setup

### 1. Install Firebase Admin SDK

#### Node.js
```bash
npm install firebase-admin
```

#### Go
```bash
go get firebase.google.com/go
```

#### Python
```bash
pip install firebase-admin
```

### 2. Initialize Firebase Admin

Place `firebase-service-account.json` in your backend project directory.

#### Node.js
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const messaging = admin.messaging();
```

#### Go
```go
import (
    "context"
    firebase "firebase.google.com/go"
    "google.golang.org/api/option"
)

ctx := context.Background()
opt := option.WithCredentialsFile("firebase-service-account.json")
app, err := firebase.NewApp(ctx, nil, opt)
if err != nil {
    log.Fatalf("error initializing app: %v\n", err)
}

client, err := app.Messaging(ctx)
firestoreClient, err := app.Firestore(ctx)
```

#### Python
```python
import firebase_admin
from firebase_admin import credentials, messaging, firestore

cred = credentials.Certificate('firebase-service-account.json')
firebase_admin.initialize_app(cred)

db = firestore.client()
```

---

## Core Functions

### Get User FCM Tokens

#### Node.js
```javascript
async function getUserTokens(userId) {
  const tokensSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('tokens')
    .get();
  
  return tokensSnapshot.docs.map(doc => doc.data().token);
}
```

#### Go
```go
func getUserTokens(ctx context.Context, userId string) ([]string, error) {
    tokensSnapshot := firestoreClient.Collection("users").Doc(userId).Collection("tokens").Documents(ctx)
    tokens := []string{}
    
    for {
        doc, err := tokensSnapshot.Next()
        if err == iterator.Done {
            break
        }
        if err != nil {
            return nil, err
        }
        
        tokenData := doc.Data()
        if token, ok := tokenData["token"].(string); ok {
            tokens = append(tokens, token)
        }
    }
    
    return tokens, nil
}
```

#### Python
```python
def get_user_tokens(user_id):
    tokens_ref = db.collection('users').document(user_id).collection('tokens')
    tokens = []
    for doc in tokens_ref.stream():
        tokens.append(doc.to_dict()['token'])
    return tokens
```

---

## Notification Functions

### 1. Ride Accepted Notification

#### Node.js
```javascript
async function notifyRideAccepted(passengerId, rideData) {
  const tokens = await getUserTokens(passengerId);
  
  if (tokens.length === 0) {
    console.log('No FCM tokens found for passenger:', passengerId);
    return { success: false, message: 'No tokens found' };
  }

  const payload = {
    notification: {
      title: 'Ride Accepted! 🚗',
      body: `Your driver ${rideData.driverName} is on the way!`,
    },
    data: {
      type: 'ride_accepted',
      rideId: rideData.rideId.toString(),
      driverName: rideData.driverName,
      driverImage: rideData.driverImage || '',
      driverPhone: rideData.driverPhone || '',
      vehicleInfo: rideData.vehicleInfo || '',
      estimatedArrival: rideData.estimatedArrival || '5 min',
    },
  };

  try {
    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
      timeToLive: 60 * 60 * 24, // 24 hours
    });
    
    console.log('Ride accepted notification sent:', response.successCount, 'successful');
    return { success: true, response };
  } catch (error) {
    console.error('Error sending ride accepted notification:', error);
    return { success: false, error };
  }
}

// Usage
await notifyRideAccepted('passenger_user_id', {
  rideId: 123,
  driverName: 'John Doe',
  driverImage: 'https://example.com/driver.jpg',
  driverPhone: '+2347012345678',
  vehicleInfo: 'Toyota Camry - ABC 123 XY',
  estimatedArrival: '5 min',
});
```

#### Go
```go
func notifyRideAccepted(ctx context.Context, passengerId string, rideData map[string]string) error {
    tokens, err := getUserTokens(ctx, passengerId)
    if err != nil {
        return err
    }
    
    if len(tokens) == 0 {
        return fmt.Errorf("no FCM tokens found for passenger: %s", passengerId)
    }
    
    message := &messaging.MulticastMessage{
        Notification: &messaging.Notification{
            Title: "Ride Accepted! 🚗",
            Body:  fmt.Sprintf("Your driver %s is on the way!", rideData["driverName"]),
        },
        Data:   rideData,
        Tokens: tokens,
        Android: &messaging.AndroidConfig{
            Priority: "high",
        },
        APNS: &messaging.APNSConfig{
            Payload: &messaging.APNSPayload{
                Aps: &messaging.Aps{
                    Sound: "default",
                },
            },
        },
    }
    
    response, err := client.SendMulticast(ctx, message)
    if err != nil {
        return err
    }
    
    log.Printf("Successfully sent %d notifications\n", response.SuccessCount)
    return nil
}
```

### 2. Driver Arrived Notification

#### Node.js
```javascript
async function notifyDriverArrived(passengerId, rideId) {
  const tokens = await getUserTokens(passengerId);
  
  const payload = {
    notification: {
      title: 'Driver Has Arrived 📍',
      body: 'Your driver has arrived at the pickup location',
    },
    data: {
      type: 'driver_arrived',
      rideId: rideId.toString(),
    },
  };

  const response = await messaging.sendToDevice(tokens, payload, {
    priority: 'high',
  });
  
  return response;
}
```

### 3. Ride Started Notification

#### Node.js
```javascript
async function notifyRideStarted(passengerId, rideData) {
  const tokens = await getUserTokens(passengerId);
  
  const payload = {
    notification: {
      title: 'Ride Started 🚀',
      body: 'Your ride has started. Enjoy your trip!',
    },
    data: {
      type: 'ride_started',
      rideId: rideData.rideId.toString(),
      destination: rideData.destination || '',
      estimatedDuration: rideData.estimatedDuration || '',
    },
  };

  const response = await messaging.sendToDevice(tokens, payload, {
    priority: 'high',
  });
  
  return response;
}
```

### 4. Ride Completed Notification

#### Node.js
```javascript
async function notifyRideCompleted(passengerId, rideData) {
  const tokens = await getUserTokens(passengerId);
  
  const payload = {
    notification: {
      title: 'Ride Completed ✅',
      body: 'Your ride is complete. Thank you for using Muvam!',
    },
    data: {
      type: 'ride_completed',
      rideId: rideData.rideId.toString(),
      fare: rideData.fare.toString(),
      distance: rideData.distance || '',
      duration: rideData.duration || '',
    },
  };

  const response = await messaging.sendToDevice(tokens, payload, {
    priority: 'high',
  });
  
  return response;
}
```

### 5. New Message Notification

#### Node.js
```javascript
async function notifyNewMessage(recipientId, messageData) {
  const tokens = await getUserTokens(recipientId);
  
  const payload = {
    notification: {
      title: 'New Message 💬',
      body: messageData.message.substring(0, 100), // Truncate long messages
    },
    data: {
      type: 'new_message',
      rideId: messageData.rideId.toString(),
      message: messageData.message,
      senderName: messageData.senderName,
      senderId: messageData.senderId.toString(),
      senderImage: messageData.senderImage || '',
      timestamp: new Date().toISOString(),
    },
  };

  const response = await messaging.sendToDevice(tokens, payload, {
    priority: 'high',
  });
  
  return response;
}

// Usage
await notifyNewMessage('driver_user_id', {
  rideId: 123,
  message: 'I am waiting at the gate',
  senderName: 'Jane Smith',
  senderId: 456,
  senderImage: 'https://example.com/passenger.jpg',
});
```

### 6. Incoming Call Notification

#### Node.js
```javascript
async function notifyIncomingCall(recipientId, callData) {
  const tokens = await getUserTokens(recipientId);
  
  const payload = {
    notification: {
      title: 'Incoming Call 📞',
      body: `${callData.callerName} is calling...`,
    },
    data: {
      type: 'incoming_call',
      sessionId: callData.sessionId,
      callerName: callData.callerName,
      callerId: callData.callerId.toString(),
      rideId: callData.rideId.toString(),
      callerImage: callData.callerImage || '',
    },
  };

  const response = await messaging.sendToDevice(tokens, payload, {
    priority: 'high',
    timeToLive: 60, // 1 minute for calls
  });
  
  return response;
}

// Usage
await notifyIncomingCall('driver_user_id', {
  sessionId: 'call_session_123',
  callerName: 'Jane Smith',
  callerId: 456,
  rideId: 123,
  callerImage: 'https://example.com/passenger.jpg',
});
```

---

## Complete Integration Example

### Express.js API Endpoints

```javascript
const express = require('express');
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const messaging = admin.messaging();
const app = express();

app.use(express.json());

// Helper function to get user tokens
async function getUserTokens(userId) {
  const tokensSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('tokens')
    .get();
  
  return tokensSnapshot.docs.map(doc => doc.data().token);
}

// Endpoint: Notify ride accepted
app.post('/api/notifications/ride-accepted', async (req, res) => {
  try {
    const { passengerId, rideId, driverName, driverImage, vehicleInfo } = req.body;
    
    const tokens = await getUserTokens(passengerId);
    
    if (tokens.length === 0) {
      return res.status(404).json({ error: 'No FCM tokens found for user' });
    }

    const payload = {
      notification: {
        title: 'Ride Accepted! 🚗',
        body: `Your driver ${driverName} is on the way!`,
      },
      data: {
        type: 'ride_accepted',
        rideId: rideId.toString(),
        driverName,
        driverImage: driverImage || '',
        vehicleInfo: vehicleInfo || '',
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    res.json({ 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount 
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Endpoint: Notify driver arrived
app.post('/api/notifications/driver-arrived', async (req, res) => {
  try {
    const { passengerId, rideId } = req.body;
    
    const tokens = await getUserTokens(passengerId);
    
    const payload = {
      notification: {
        title: 'Driver Has Arrived 📍',
        body: 'Your driver has arrived at the pickup location',
      },
      data: {
        type: 'driver_arrived',
        rideId: rideId.toString(),
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    res.json({ success: true, successCount: response.successCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint: Notify ride started
app.post('/api/notifications/ride-started', async (req, res) => {
  try {
    const { passengerId, rideId, destination } = req.body;
    
    const tokens = await getUserTokens(passengerId);
    
    const payload = {
      notification: {
        title: 'Ride Started 🚀',
        body: 'Your ride has started. Enjoy your trip!',
      },
      data: {
        type: 'ride_started',
        rideId: rideId.toString(),
        destination: destination || '',
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    res.json({ success: true, successCount: response.successCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint: Notify ride completed
app.post('/api/notifications/ride-completed', async (req, res) => {
  try {
    const { passengerId, rideId, fare, distance, duration } = req.body;
    
    const tokens = await getUserTokens(passengerId);
    
    const payload = {
      notification: {
        title: 'Ride Completed ✅',
        body: 'Your ride is complete. Thank you for using Muvam!',
      },
      data: {
        type: 'ride_completed',
        rideId: rideId.toString(),
        fare: fare.toString(),
        distance: distance || '',
        duration: duration || '',
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    res.json({ success: true, successCount: response.successCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint: Notify new message
app.post('/api/notifications/new-message', async (req, res) => {
  try {
    const { recipientId, rideId, message, senderName, senderId, senderImage } = req.body;
    
    const tokens = await getUserTokens(recipientId);
    
    const payload = {
      notification: {
        title: 'New Message 💬',
        body: message.substring(0, 100),
      },
      data: {
        type: 'new_message',
        rideId: rideId.toString(),
        message,
        senderName,
        senderId: senderId.toString(),
        senderImage: senderImage || '',
        timestamp: new Date().toISOString(),
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    res.json({ success: true, successCount: response.successCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Endpoint: Notify incoming call
app.post('/api/notifications/incoming-call', async (req, res) => {
  try {
    const { recipientId, sessionId, callerName, callerId, rideId, callerImage } = req.body;
    
    const tokens = await getUserTokens(recipientId);
    
    const payload = {
      notification: {
        title: 'Incoming Call 📞',
        body: `${callerName} is calling...`,
      },
      data: {
        type: 'incoming_call',
        sessionId,
        callerName,
        callerId: callerId.toString(),
        rideId: rideId.toString(),
        callerImage: callerImage || '',
      },
    };

    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
      timeToLive: 60, // 1 minute
    });
    
    res.json({ success: true, successCount: response.successCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Notification server running on port ${PORT}`);
});
```

---

## Testing

### Using cURL

```bash
# Test ride accepted notification
curl -X POST http://localhost:3000/api/notifications/ride-accepted \
  -H "Content-Type: application/json" \
  -d '{
    "passengerId": "user_123",
    "rideId": 456,
    "driverName": "John Doe",
    "driverImage": "https://example.com/driver.jpg",
    "vehicleInfo": "Toyota Camry - ABC 123 XY"
  }'

# Test new message notification
curl -X POST http://localhost:3000/api/notifications/new-message \
  -H "Content-Type: application/json" \
  -d '{
    "recipientId": "driver_789",
    "rideId": 456,
    "message": "I am waiting at the gate",
    "senderName": "Jane Smith",
    "senderId": 123,
    "senderImage": "https://example.com/passenger.jpg"
  }'
```

---

## Best Practices

### 1. Error Handling
```javascript
async function sendNotificationWithRetry(tokens, payload, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await messaging.sendToDevice(tokens, payload, {
        priority: 'high',
      });
      
      // Remove invalid tokens
      if (response.failureCount > 0) {
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
          if (result.error) {
            console.error('Error sending to token:', result.error);
            if (result.error.code === 'messaging/invalid-registration-token' ||
                result.error.code === 'messaging/registration-token-not-registered') {
              tokensToRemove.push(tokens[index]);
            }
          }
        });
        
        // Clean up invalid tokens from Firestore
        await removeInvalidTokens(tokensToRemove);
      }
      
      return response;
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      console.log(`Retry attempt ${attempt} failed, retrying...`);
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
    }
  }
}
```

### 2. Token Cleanup
```javascript
async function removeInvalidTokens(tokens) {
  const batch = db.batch();
  
  for (const token of tokens) {
    // Find and delete the token document
    const tokensSnapshot = await db.collectionGroup('tokens')
      .where('token', '==', token)
      .get();
    
    tokensSnapshot.forEach(doc => {
      batch.delete(doc.ref);
    });
  }
  
  await batch.commit();
  console.log(`Removed ${tokens.length} invalid tokens`);
}
```

### 3. Logging and Monitoring
```javascript
async function sendNotificationWithLogging(userId, type, payload) {
  const startTime = Date.now();
  
  try {
    const tokens = await getUserTokens(userId);
    const response = await messaging.sendToDevice(tokens, payload, {
      priority: 'high',
    });
    
    const duration = Date.now() - startTime;
    
    // Log to your monitoring system
    console.log({
      event: 'notification_sent',
      userId,
      type,
      successCount: response.successCount,
      failureCount: response.failureCount,
      duration,
      timestamp: new Date().toISOString(),
    });
    
    return response;
  } catch (error) {
    console.error({
      event: 'notification_error',
      userId,
      type,
      error: error.message,
      timestamp: new Date().toISOString(),
    });
    throw error;
  }
}
```

---

## Production Checklist

- [ ] Firebase Admin SDK installed and configured
- [ ] Service account JSON file secured (not in version control)
- [ ] Error handling implemented
- [ ] Invalid token cleanup implemented
- [ ] Logging and monitoring set up
- [ ] Rate limiting implemented (if needed)
- [ ] All 6 notification types tested
- [ ] Multi-device delivery tested
- [ ] Retry logic implemented
- [ ] Performance monitoring in place

---

**Last Updated:** December 31, 2025  
**Version:** 1.0.0
