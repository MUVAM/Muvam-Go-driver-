import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/services/firebase_config_service.dart';

class CallNotificationService {
  /// Send call notification with action buttons (Accept/Reject)
  static Future<void> sendCallNotificationWithActions({
    required String deviceToken,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    print('📤 FCM CALL DEBUG: Starting sendCallNotificationWithActions');
    print(
      '📤 FCM CALL DEBUG: Token: ${deviceToken.substring(0, 20)}..., Title: $title, Body: $body',
    );

    try {
      print('🔑 FCM CALL DEBUG: Getting access token');
      final String serverAccessToken = await _getAccessToken();
      print('✅ FCM CALL DEBUG: Access token obtained successfully');

      String endpointFirebasecloudMessaging =
          'https://fcm.googleapis.com/v1/projects/muvam-go/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {'title': title, 'body': body},
          'data': {
            'type': type,
            'vibrate': 'true',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            ...?additionalData,
          },
          'android': {
            'priority': "high",
            'notification': {
              'sound': "default",
              'click_action': "FLUTTER_NOTIFICATION_CLICK",
              'channel_id': "incoming_call_channel",
              'vibrate_timings': ["0s", "0.5s", "0.2s", "0.5s"],
              'tag': 'call_notification',
              'sticky': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'contentAvailable': true,
                'badge': 1,
                'sound': "default",
                'category': 'CALL_CATEGORY',
              },
            },
          },
        },
      };

      print('📦 FCM CALL DEBUG: Message payload prepared');
      print('📤 FCM CALL DEBUG: Sending HTTP POST request to FCM');

      final response = await http.post(
        Uri.parse(endpointFirebasecloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessToken',
        },
        body: jsonEncode(message),
      );

      print(
        '📝 FCM CALL DEBUG: FCM Response - Status Code: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
          '✅ FCM CALL DEBUG: Call notification sent successfully! Response: $responseData',
        );
      } else {
        print(
          '❌ FCM CALL DEBUG: FCM request failed with status: ${response.statusCode}',
        );
        print('❌ FCM CALL DEBUG: Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print(
        '💥 FCM CALL DEBUG: Exception in sendCallNotificationWithActions: $e',
      );
      print('💥 FCM CALL DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<String> _getAccessToken() async {
    final serviceAccountJson =
        await FirebaseConfigService.getServiceAccountConfig();
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );
    client.close();
    return credentials.accessToken.data;
  }
}
