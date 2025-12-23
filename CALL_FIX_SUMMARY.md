# Call System Fix Summary

## Problem Description
When the driver tried to call the passenger:
- The call was ringing on the driver's own app (showing incoming call screen)
- The passenger app did NOT receive the incoming call notification
- When the passenger tried to call back, the driver did NOT see the incoming call

## Root Cause
The WebSocket service was routing ALL call messages to EVERY connected user without filtering by recipient. This meant:

1. **Driver initiates call** → Server sends `call_initiate` message
2. **Driver's app receives the message** → Shows incoming call screen (WRONG!)
3. **Passenger's app also receives the message** → But the filtering logic was missing, so it might not have been processed correctly

The issue was in `websocket_service.dart` in the `_handleMessage()` method:
```dart
case 'call_initiate':
  // This was being called for EVERYONE, including the caller!
  if (onIncomingCall != null) onIncomingCall!(data);
  break;
```

## Solution Implemented

### 1. Added Message Filtering in WebSocket Service
Created a new method `_handleCallMessage()` that filters call messages based on the current user's ID:

```dart
Future<void> _handleCallMessage(Map<String, dynamic> data, String type) async {
  final currentUserId = prefs.getString('user_id');
  final callerId = messageData['caller_id']?.toString();
  final recipientId = messageData['recipient_id']?.toString();
  
  // For call_initiate: only show to recipient (not the caller)
  if (type == 'call_initiate') {
    if (recipientId == currentUserId) {
      // Show incoming call to recipient
      if (onIncomingCall != null) onIncomingCall!(data);
    } else if (callerId == currentUserId) {
      // Ignore - this is the caller's own call
    }
  }
  // ... handle other call message types
}
```

### 2. Message Routing Logic

**For `call_initiate`:**
- ✅ Show ONLY to the recipient (passenger)
- ❌ Do NOT show to the caller (driver)

**For `call_answer`, `call_reject`, `call_end`:**
- ✅ Route to the caller (driver) to update their call state
- ❌ Do NOT route to the recipient

**For WebRTC signaling (`call_offer`, `call_answer_sdp`, `call_ice_candidate`):**
- ✅ Route to the intended recipient based on `recipient_id`
- These messages establish the peer-to-peer connection

### 3. Enhanced Logging
Added detailed logging in both `websocket_service.dart` and `call_service.dart` to track:
- Current user ID
- Caller ID and Recipient ID from messages
- Message routing decisions
- Why messages are being filtered or passed through

## Expected Behavior After Fix

### Scenario 1: Driver Calls Passenger
1. Driver presses call button
2. Driver sees "Ringing..." status (NOT incoming call screen)
3. Passenger receives incoming call notification
4. Passenger can accept or reject
5. When accepted, both connect via WebRTC

### Scenario 2: Passenger Calls Driver
1. Passenger presses call button
2. Passenger sees "Ringing..." status
3. Driver receives incoming call notification
4. Driver can accept or reject
5. When accepted, both connect via WebRTC

## Files Modified

1. **`lib/core/services/websocket_service.dart`**
   - Modified `_handleMessage()` to call new filtering method for call messages
   - Added `_handleCallMessage()` method with user ID filtering logic
   - Added detailed logging for debugging

2. **`lib/core/services/call_service.dart`**
   - Enhanced logging in `_handleWebSocketMessage()` to show message data
   - Added session/ride/caller ID logging for better debugging

## Testing Recommendations

1. **Test Driver → Passenger Call:**
   - Driver initiates call
   - Verify driver sees "Ringing..." (not incoming call screen)
   - Verify passenger sees incoming call notification
   - Accept call and verify audio works

2. **Test Passenger → Driver Call:**
   - Passenger initiates call
   - Verify passenger sees "Ringing..." (not incoming call screen)
   - Verify driver sees incoming call notification
   - Accept call and verify audio works

3. **Check Logs:**
   - Look for "CALL MESSAGE FILTERING" logs
   - Verify user IDs are being compared correctly
   - Ensure messages are routed to correct recipients

## Additional Notes

- The fix assumes that the server is sending `caller_id` and `recipient_id` in the message data
- If these fields are missing or have different names, the filtering logic may need adjustment
- The `user_id` is retrieved from SharedPreferences with key `'user_id'`
- Make sure both apps (driver and passenger) have the correct user ID stored in SharedPreferences
