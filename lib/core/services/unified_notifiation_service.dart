import 'package:muvam_rider/core/services/call_notification_helper.dart';
import 'package:muvam_rider/core/services/fcm_token_service.dart';
import 'package:muvam_rider/core/services/fcm_notification_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class UnifiedNotificationService {
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatRoomId,
    bool type = true,
  }) async {
    // final greeting = _getGreeting(receiverName);
    // Get receiver's FCM tokens
    final tokens = await FCMTokenService.getTokensForUser(receiverId);
    if (tokens.isEmpty) {
      return;
    }
    // Send notification to all user's devices
    for (String token in tokens) {
      try {
        await EnhancedNotificationService.sendNotificationWithVibration(
          deviceToken: token,
          title: "New Message From Driver",
          body: 'New Message: $messageText',
          type: 'chat_message',
          additionalData: {
            'chatRoomId': chatRoomId,
            'senderId': senderName,
            'messageText': messageText,
          },
        );
      } catch (e) {
        if (e is InvalidTokenException) {
          await FCMTokenService.removeInvalidToken(receiverId, token);
        }
      }
    }
    // Don't store chat messages in notification collection
    // Chat messages are handled separately in chatRooms collection
  }

  static Future<void> sendRideNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatRoomId,
  }) async {
    // Get receiver's FCM tokens
    final tokens = await FCMTokenService.getTokensForUser(receiverId);
    if (tokens.isEmpty) {
      return;
    }
    // Send notification to all user's devices
    for (String token in tokens) {
      try {
        await EnhancedNotificationService.sendNotificationWithVibration(
          deviceToken: token,
          title: "Ride Status",
          body: messageText,
          type: 'chat_message',
          additionalData: {
            'chatRoomId': chatRoomId,
            'senderId': senderName,
            'messageText': messageText,
          },
        );
      } catch (e) {
        if (e is InvalidTokenException) {
          await FCMTokenService.removeInvalidToken(receiverId, token);
        }
      }
    }
    // Don't store chat messages in notification collection
    // Chat messages are handled separately in chatRooms collection
  }

  static Future<void> sendCallNotification({
    required String receiverId,
    required String callerName,
    required int rideId,
    required int sessionId,
    String? callerImage,
  }) async {
    try {
      // Get receiver's FCM tokens
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      if (tokens.isEmpty) {
        AppLogger.log('CALL_NOTIF: No FCM tokens found for user $receiverId');
        return;
      }

      AppLogger.log('CALL_NOTIF: Sending call notification to $receiverId');
      AppLogger.log(
        'CALL_NOTIF: Caller: $callerName, Ride: $rideId, Session: $sessionId',
      );

      // Send notification to all user's devices
      for (String token in tokens) {
        try {
          await CallNotificationService.sendCallNotificationWithActions(
            deviceToken: token,
            title: "Incoming Call",
            body: '$callerName is calling you',
            type: 'incoming_call',
            additionalData: {
              'caller_name': callerName,
              'caller_image': callerImage ?? '',
              'ride_id': rideId.toString(),
              'session_id': sessionId.toString(),
              'call_type': 'voice',
              'priority': 'high',
            },
          );
          AppLogger.log(
            'CALL_NOTIF: Notification sent to token: ${token.substring(0, 20)}...',
          );
        } catch (e) {
          AppLogger.log('CALL_NOTIF: Failed to send to token: $e');
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
    } catch (e) {
      AppLogger.log('CALL_NOTIF: Error sending call notification: $e');
    }
  }
}
