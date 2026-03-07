import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/config/routes/app_router.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/services/fcm_token_service.dart';
import 'package:muvam_rider/core/services/firebase_config_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:muvam_rider/core/utils/extension.dart';

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException(this.message);

  @override
  String toString() => 'InvalidTokenException: $message';
}

class EnhancedNotificationService {
  static Future<String> getAccessToken() async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> sendNotificationWithVibration({
    required String deviceToken,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    AppLogger.log(
      'FCM DEBUG: Token: ${deviceToken.substring(0, 20)}..., Title: $title, Body: $body, Type: $type',
    );

    try {
      final String serverAccessToken = await getAccessToken();

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
              'channel_id': "FoodHub",
              'vibrate_timings': ["0s", "0.5s", "0.2s", "0.5s"],
            },
          },
          'apns': {
            'payload': {
              'aps': {'contentAvailable': true, 'badge': 1, 'sound': "default"},
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(endpointFirebasecloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        AppLogger.log(
          'FCM DEBUG: Notification sent successfully! Response: $responseData',
        );
      } else {
        try {
          final errorData = jsonDecode(response.body);

          if (response.statusCode == 400 || response.statusCode == 404) {
            final errorMessage = errorData['error']?['message'] ?? '';
            if (errorMessage.contains('not a valid FCM registration token') ||
                errorMessage.contains('Requested entity was not found')) {
              throw InvalidTokenException('Invalid FCM token: $deviceToken');
            }
          }
        } catch (e) {
          if (e is InvalidTokenException) {
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log(
        'FCM DEBUG: Exception in sendNotificationWithVibration: $e',
      );
      rethrow;
    }
  }

  static String _getGreeting(String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning $userName";
    } else if (hour < 17) {
      return "Good Afternoon $userName";
    } else {
      return "Good Evening $userName";
    }
  }

  static Future<void> sendLikeNotification({
    required String postOwnerId,
    required String likerName,
    required String postId,
  }) async {
    try {
      String userName = 'User';

      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(postOwnerId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
      } else {
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(postOwnerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
        }
      }

      final greeting = _getGreeting(userName);

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(postOwnerId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];

        if (tokenList.isEmpty) {
          await _attemptTokenRefresh(postOwnerId);
          docSnapshot = await userTokenCollection.doc(postOwnerId).get();
          if (docSnapshot.exists) {
            tokenList = docSnapshot['token'] ?? [];
          }
        }

        for (String token in tokenList) {
          try {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: greeting,
              body: "You have a like on your post",
              type: "like_notification",
              additionalData: {'postId': postId, 'likerId': likerName},
            );
          } catch (e) {
            if (e is InvalidTokenException) {
              await FCMTokenService.removeInvalidToken(postOwnerId, token);
            }
          }
        }
      } else {
        await _attemptTokenRefresh(postOwnerId);
      }

      await _storeNotificationInFirestore(
        userId: postOwnerId,
        title: "Like Notification",
        body: "$likerName liked your post",
        type: "like",
        additionalData: {'postId': postId, 'likerId': likerName},
      );
    } catch (e) {}
  }

  static Future<void> sendReplyNotification({
    required String commentAuthorId,
    required String replierName,
    required String postId,
    required String replyText,
    required String commentId,
  }) async {
    try {
      String userName = 'User';

      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(commentAuthorId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
      } else {
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(commentAuthorId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
        }
      }

      final greeting = _getGreeting(userName);

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(commentAuthorId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];

        if (tokenList.isEmpty) {
          await _attemptTokenRefresh(commentAuthorId);
          docSnapshot = await userTokenCollection.doc(commentAuthorId).get();
          if (docSnapshot.exists) {
            tokenList = docSnapshot['token'] ?? [];
          }
        }

        for (String token in tokenList) {
          try {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: greeting,
              body: "$replierName replied to your comment",
              type: "reply_notification",
              additionalData: {
                'postId': postId,
                'commentId': commentId,
                'replierId': replierName,
                'replyText': replyText,
              },
            );
          } catch (e) {
            if (e is InvalidTokenException) {
              await FCMTokenService.removeInvalidToken(commentAuthorId, token);
            }
          }
        }
      } else {
        await _attemptTokenRefresh(commentAuthorId);
      }

      await _storeNotificationInFirestore(
        userId: commentAuthorId,
        title: "Reply Notification",
        body: "$replierName replied to your comment",
        type: "reply",
        additionalData: {
          'postId': postId,
          'commentId': commentId,
          'replierId': replierName,
        },
      );
    } catch (e) {}
  }

  static Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterName,
    required String postId,
    required String commentText,
    String? parentCommentId,
    String? parentCommentAuthorId,
  }) async {
    try {
      String userName = 'User';

      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(postOwnerId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
      } else {
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(postOwnerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
        }
      }

      final greeting = _getGreeting(userName);

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(postOwnerId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];

        for (String token in tokenList) {
          await sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: "You have a comment on your post",
            type: "comment_notification",
            additionalData: {
              'postId': postId,
              'commenterId': commenterName,
              'commentText': commentText,
            },
          );
        }
      }

      await _storeNotificationInFirestore(
        userId: postOwnerId,
        title: "Comment Notification",
        body: "$commenterName commented on your post",
        type: "comment",
        additionalData: {'postId': postId, 'commenterId': commenterName},
      );

      if (parentCommentId != null &&
          parentCommentAuthorId != null &&
          parentCommentAuthorId != postOwnerId) {
        String parentAuthorName = 'User';

        var userDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(parentCommentAuthorId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          parentAuthorName = userData?['name'] as String? ?? 'User';
        } else {
          userDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(parentCommentAuthorId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            parentAuthorName =
                userData?['username'] as String? ??
                userData?['name'] as String? ??
                'User';
          }
        }

        final replyGreeting = _getGreeting(parentAuthorName);

        CollectionReference userTokenCollection = FirebaseFirestore.instance
            .collection('UserToken');

        DocumentSnapshot docSnapshot = await userTokenCollection
            .doc(parentCommentAuthorId)
            .get();

        if (docSnapshot.exists) {
          List<dynamic> tokenList = docSnapshot['token'] ?? [];

          for (String token in tokenList) {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: replyGreeting,
              body: "$commenterName replied to your comment",
              type: "comment_reply_notification",
              additionalData: {
                'postId': postId,
                'commenterId': commenterName,
                'parentCommentId': parentCommentId,
                'commentText': commentText,
              },
            );
          }
        }

        await _storeNotificationInFirestore(
          userId: parentCommentAuthorId,
          title: "Reply Notification",
          body: "$commenterName replied to your comment",
          type: "comment_reply",
          additionalData: {
            'postId': postId,
            'commenterId': commenterName,
            'parentCommentId': parentCommentId,
          },
        );
      }
    } catch (e) {}
  }

  static Future<void> sendAdminPostNotification({
    required String adminName,
    required String postContent,
  }) async {
    try {
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('UserToken')
          .get();

      for (var tokenDoc in tokenSnapshot.docs) {
        final tokenData = tokenDoc.data();
        final userId = tokenDoc.id;
        final tokenList = List<String>.from(tokenData['token'] ?? []);

        String userName = 'User';

        var userDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['name'] as String? ?? 'User';
        } else {
          userDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            userName =
                userData?['username'] as String? ??
                userData?['name'] as String? ??
                'User';
          }
        }

        final greeting = _getGreeting(userName);

        for (String token in tokenList) {
          await sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: "$adminName just posted",
            type: "admin_post_notification",
            additionalData: {
              'adminName': adminName,
              'postContent': postContent,
            },
          );
        }

        await _storeNotificationInFirestore(
          userId: userId,
          title: "New Post",
          body: "$adminName just posted",
          type: "admin_post",
          additionalData: {'adminName': adminName},
        );
      }
    } catch (e) {}
  }

  static Future<void> _storeNotificationInFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'sellerId':
            additionalData?['likerId'] ??
            additionalData?['commenterId'] ??
            additionalData?['adminName'] ??
            '',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': type,
        'postId': additionalData?['postId'] ?? '',
        'commentId':
            additionalData?['commentId'] ??
            additionalData?['parentCommentId'] ??
            '',
        ...?additionalData,
      };

      await FirebaseFirestore.instance
          .collection('NotificationWp')
          .doc(userId)
          .collection('notification')
          .add(notificationData);
    } catch (e) {}
  }

  static Future<void> triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 128, 0, 255],
        );
      }
    } catch (e) {}
  }

  static void initEnhancedNotifications() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'FoodHub',
      'WorkPal Notifications',
      description: 'Notifications for WorkPal app',
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    var androidInitialize = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var iosInitialize = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            await triggerVibration();

            final context = AppRouter.navigationKey.currentContext;
            if (context != null) {
              context.pushNamedAndClear(AppRoutes.home.name);
            }
            if (notificationResponse.payload != null) {
              await _handleNotificationTap(notificationResponse.payload!);
            }
          },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        if (message.data['vibrate'] == 'true') {
          await triggerVibration();
        }

        BigTextStyleInformation bigTextStyleInformation =
            BigTextStyleInformation(
              message.notification!.body.toString(),
              htmlFormatBigText: true,
              contentTitle: message.notification!.title.toString(),
              htmlFormatContentTitle: true,
            );

        AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
              "FoodHub",
              "WorkPal Notifications",
              channelDescription: 'Notifications for WorkPal app',
              importance: Importance.high,
              playSound: true,
              priority: Priority.high,
              styleInformation: bigTextStyleInformation,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
              icon: '@drawable/ic_notification',
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/launcher_icon',
              ),
            );

        NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
          iOS: const DarwinNotificationDetails(),
        );

        String payload = '';
        if (message.data['postId'] != null) {
          payload = 'postId:${message.data['postId']}';
        }

        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          notificationDetails,
          payload: payload,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await triggerVibration();

      final context = AppRouter.navigationKey.currentContext;
      if (context != null) {
        context.pushNamedAndClear(AppRoutes.home.name);
      }

      if (message.data['postId'] != null) {
        await _handleNotificationTap('postId:${message.data['postId']}');
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) async {
      if (message != null && message.data['postId'] != null) {
        await Future.delayed(const Duration(seconds: 1));

        final context = AppRouter.navigationKey.currentContext;
        if (context != null) {
          context.pushNamedAndClear(AppRoutes.home.name);
        }
        _handleNotificationTap('postId:${message.data['postId']}');
      }
    });
  }

  static Future<void> _handleNotificationTap(String payload) async {
    if (payload.startsWith('postId:')) {
      final postId = payload.substring(7);
      _pendingPostNavigation = postId;
    }
  }

  static String? _pendingPostNavigation;

  static String? getPendingPostNavigation() {
    final postId = _pendingPostNavigation;
    _pendingPostNavigation = null;
    return postId;
  }

  static Future<void> _attemptTokenRefresh(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('user_id');

      if (currentUser != null && currentUser == userId) {
        await FCMTokenService.ensureCurrentUserTokenStored();
      }
    } catch (e) {}
  }
}
