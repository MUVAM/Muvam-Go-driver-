import 'dart:convert';

import 'package:flutter/services.dart';

/// Service to load Firebase service account configuration
/// This is used by the backend to get OAuth tokens for sending notifications
class FirebaseConfigService {
  /// Get service account configuration from assets
  /// Note: In production, this should be loaded from secure storage or backend
  static Future<Map<String, dynamic>> getServiceAccountConfig() async {
    try {
      // Load from assets (for development/testing)
      // In production, your BACKEND should have this file, not the app
      final String jsonString = await rootBundle.loadString(
        'assets/firebase-service-account.json',
      );
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Failed to load Firebase service account config: $e');
    }
  }
}
