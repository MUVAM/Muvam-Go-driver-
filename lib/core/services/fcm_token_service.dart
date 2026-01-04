import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFCM() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _setupTokenHandling();
      } else {}
    } catch (e) {}
  }

  static Future<void> _setupTokenHandling() async {
    try {
      await _getCurrentTokenAndStore();
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _storeTokenForCurrentUser(newToken);
      });
    } catch (e) {}
  }

  static Future<void> _getCurrentTokenAndStore() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeTokenForCurrentUser(token);
      } else {}
    } catch (e) {}
  }

  static Future<void> _storeTokenForCurrentUser(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        return;
      }
      await storeTokenForUser(user, token);
    } catch (e) {}
  }

  static Future<void> storeTokenForUser(String userId, String token) async {
    AppLogger.log('FCM_TOKEN DEBUG: Storing token for userId: $userId');
    AppLogger.log('FCM_TOKEN DEBUG: Token: ${token.substring(0, 20)}...');

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      final doc = await userTokenRef.get();
      if (doc.exists) {
        AppLogger.log('FCM_TOKEN DEBUG: Document exists, updating token array');
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> existingTokens = data['token'] ?? [];
        AppLogger.log(
          'FCM_TOKEN DEBUG: Existing tokens count: ${existingTokens.length}',
        );

        existingTokens.removeWhere((existingToken) => existingToken == token);
        existingTokens.insert(0, token);
        if (existingTokens.length > 3) {
          existingTokens = existingTokens.take(3).toList();
        }

        AppLogger.log(
          'FCM_TOKEN DEBUG: Updated tokens count: ${existingTokens.length}',
        );

        await userTokenRef.update({
          'token': existingTokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log('FCM_TOKEN DEBUG: Token updated successfully');
      } else {
        AppLogger.log(
          'FCM_TOKEN DEBUG: Document doesn\'t exist, creating new one',
        );
        await userTokenRef.set({
          'token': [token],
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log(
          'FCM_TOKEN DEBUG: New token document created successfully',
        );
      }
    } catch (e) {
      AppLogger.log('FCM_TOKEN DEBUG: Error storing token: $e');
    }
  }

  static Future<void> ensureCurrentUserTokenStored() async {
    AppLogger.log('FCM_TOKEN DEBUG: Starting ensureCurrentUserTokenStored');

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        AppLogger.log('FCM_TOKEN DEBUG: No authenticated user found');
        return;
      }

      AppLogger.log('FCM_TOKEN DEBUG: Checking tokens for user: ${user}');

      final userTokenDoc = await _firestore
          .collection('UserToken')
          .doc(user)
          .get();

      if (!userTokenDoc.exists) {
        AppLogger.log(
          'FCM_TOKEN DEBUG: No token document exists, creating new one',
        );
        await _getCurrentTokenAndStore();
      } else {
        final tokens = userTokenDoc.data()?['token'] as List?;
        if (tokens?.isEmpty == true) {
          AppLogger.log(
            'FCM_TOKEN DEBUG: Token document exists but is empty, refreshing',
          );
          await _getCurrentTokenAndStore();
        } else {
          AppLogger.log(
            'FCM_TOKEN DEBUG: Token document exists with ${tokens?.length} tokens, refreshing anyway',
          );
          await _getCurrentTokenAndStore();
        }
      }
    } catch (e) {
      AppLogger.log(
        'FCM_TOKEN DEBUG: Error in ensureCurrentUserTokenStored: $e',
      );
    }
  }

  static Future<List<String>> getTokensForUser(String userId) async {
    AppLogger.log('FCM_TOKEN DEBUG: Getting tokens for userId: $userId');

    try {
      final doc = await _firestore.collection('UserToken').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tokens = List<String>.from(data['token'] ?? []);
        AppLogger.log(
          'FCM_TOKEN DEBUG: Found ${tokens.length} tokens for user $userId',
        );
        for (int i = 0; i < tokens.length; i++) {
          AppLogger.log(
            'FCM_TOKEN DEBUG: Token $i: ${tokens[i].substring(0, 20)}...',
          );
        }
        return tokens;
      } else {
        AppLogger.log(
          'FCM_TOKEN DEBUG: No token document found for user $userId',
        );
      }
      return [];
    } catch (e) {
      AppLogger.log(
        'FCM_TOKEN DEBUG: Error getting tokens for user $userId: $e',
      );
      return [];
    }
  }

  static Future<void> removeInvalidToken(
    String userId,
    String invalidToken,
  ) async {
    AppLogger.log(
      'FCM_TOKEN DEBUG: Removing invalid token for userId: $userId',
    );
    AppLogger.log(
      'FCM_TOKEN DEBUG: Invalid token: ${invalidToken.substring(0, 20)}...',
    );

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      final doc = await userTokenRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> tokens = data['token'] ?? [];
        final originalCount = tokens.length;
        tokens.removeWhere((token) => token == invalidToken);
        final newCount = tokens.length;

        AppLogger.log(
          'FCM_TOKEN DEBUG: Removed ${originalCount - newCount} invalid tokens',
        );
        AppLogger.log('FCM_TOKEN DEBUG: Remaining tokens: $newCount');

        await userTokenRef.update({
          'token': tokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log('FCM_TOKEN DEBUG: Invalid token removed successfully');
      } else {
        AppLogger.log(
          'FCM_TOKEN DEBUG: No token document found for user $userId',
        );
      }
    } catch (e) {
      AppLogger.log('FCM_TOKEN DEBUG: Error removing invalid token: $e');
    }
  }
}
