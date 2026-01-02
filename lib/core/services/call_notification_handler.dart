import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CallNotificationHandler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    print('📞 CALL_HANDLER: Initializing call notification handler');

    // Create a high-priority notification channel for incoming calls
    final AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'incoming_call_channel',
      'Incoming Calls',
      description: 'Notifications for incoming calls',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('ringtone'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callChannel);

    // Initialize with action buttons support
    const AndroidInitializationSettings androidInitialize =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosInitialize =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    print('✅ CALL_HANDLER: Call notification handler initialized');
  }

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    print('📞 CALL_HANDLER: Notification response received');
    print('📞 CALL_HANDLER: Action ID: ${response.actionId}');
    print('📞 CALL_HANDLER: Payload: ${response.payload}');

    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!);
      final String? actionId = response.actionId;

      if (actionId == 'accept_call') {
        print('✅ CALL_HANDLER: User accepted the call');
        await _handleAcceptCall(data);
      } else if (actionId == 'reject_call') {
        print('❌ CALL_HANDLER: User rejected the call');
        await _handleRejectCall(data);
      } else {
        // Default tap - open the app to call screen
        print('📱 CALL_HANDLER: User tapped notification');
        await _handleAcceptCall(data);
      }
    } catch (e) {
      print('❌ CALL_HANDLER: Error handling notification response: $e');
    }
  }

  static Future<void> _handleAcceptCall(Map<String, dynamic> data) async {
    print('📞 CALL_HANDLER: Handling accept call');

    // Store the call data for navigation
    final callData = {
      'action': 'accept',
      'caller_name': data['caller_name'],
      'caller_image': data['caller_image'],
      'ride_id': data['ride_id'],
      'session_id': data['session_id'],
    };

    // Store in a global variable or shared preferences for the app to pick up
    _pendingCallAction = callData;

    print('✅ CALL_HANDLER: Call acceptance data stored');
  }

  static Future<void> _handleRejectCall(Map<String, dynamic> data) async {
    print('📞 CALL_HANDLER: Handling reject call');

    // You can send a rejection message to the server here
    // For now, just dismiss the notification
    await _notificationsPlugin.cancel(999); // Call notification ID

    print('✅ CALL_HANDLER: Call rejected and notification dismissed');
  }

  static Map<String, dynamic>? _pendingCallAction;

  static Map<String, dynamic>? getPendingCallAction() {
    final action = _pendingCallAction;
    _pendingCallAction = null; // Clear after reading
    return action;
  }

  /// Show incoming call notification with action buttons
  static Future<void> showIncomingCallNotification({
    required String callerName,
    required String callerImage,
    required String rideId,
    required String sessionId,
  }) async {
    print('📞 CALL_HANDLER: Showing incoming call notification');
    print('📞 CALL_HANDLER: Caller: $callerName, Ride: $rideId');

    final payload = jsonEncode({
      'caller_name': callerName,
      'caller_image': callerImage,
      'ride_id': rideId,
      'session_id': sessionId,
      'type': 'incoming_call',
    });

    // Create action buttons
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'incoming_call_channel',
          'Incoming Calls',
          channelDescription: 'Notifications for incoming calls',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('ringtone'),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'reject_call',
              'Reject',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_call_end'),
              cancelNotification: true,
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'accept_call',
              'Accept',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_call'),
              cancelNotification: true,
              showsUserInterface: true,
            ),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ringtone.aiff',
      categoryIdentifier: 'CALL_CATEGORY',
    );

     NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      999, // Use a fixed ID for call notifications
      'Incoming Call',
      '$callerName is calling you',
      notificationDetails,
      payload: payload,
    );

    print('✅ CALL_HANDLER: Incoming call notification shown');
  }

  /// Cancel the incoming call notification
  static Future<void> cancelCallNotification() async {
    await _notificationsPlugin.cancel(999);
    print('✅ CALL_HANDLER: Call notification cancelled');
  }
}
