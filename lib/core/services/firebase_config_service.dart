import 'package:muvam_rider/core/config/firebase_service_account.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class FirebaseConfigService {
  static Map<String, dynamic>? _cachedConfig;

  static Future<Map<String, dynamic>> getServiceAccountConfig() async {
    AppLogger.log('CONFIG DEBUG: Starting getServiceAccountConfig');

    // Return cached config if available
    if (_cachedConfig != null) {
      AppLogger.log('CONFIG DEBUG: Using cached config');
      return _cachedConfig!;
    }

    try {
      AppLogger.log('CONFIG DEBUG: Loading service account from Dart constant');

      // Load from Dart constant file
      _cachedConfig = Map<String, dynamic>.from(
        FirebaseServiceAccount.credentials,
      );

      AppLogger.log('CONFIG DEBUG: Service account config loaded and cached');

      // Validate the config
      final privateKey = _cachedConfig!["private_key"] as String;
      final projectId = _cachedConfig!["project_id"] as String;
      final clientEmail = _cachedConfig!["client_email"] as String;

      AppLogger.log('CONFIG DEBUG: Project ID: $projectId');
      AppLogger.log('CONFIG DEBUG: Client Email: $clientEmail');
      AppLogger.log('CONFIG DEBUG: Has private_key: ${privateKey.isNotEmpty}');
      AppLogger.log('CONFIG DEBUG: Private key length: ${privateKey.length}');
      AppLogger.log(
        'CONFIG DEBUG: Has BEGIN marker: ${privateKey.contains('-----BEGIN')}',
      );
      AppLogger.log(
        'CONFIG DEBUG: Has END marker: ${privateKey.contains('-----END')}',
      );

      // Check if credentials are placeholder values
      if (privateKey.contains('YOUR_PRIVATE_KEY_HERE') ||
          clientEmail.contains('YOUR_CLIENT_EMAIL_HERE')) {
        AppLogger.log('CONFIG DEBUG: Credentials contain placeholder values!');
        AppLogger.log(
          'Please update lib/core/config/firebase_service_account.dart with actual credentials',
        );
        throw Exception(
          'Firebase service account credentials not configured. Please update firebase_service_account.dart',
        );
      }

      return _cachedConfig!;
    } catch (e) {
      AppLogger.log('CONFIG DEBUG: Error loading Firebase config: $e');
      AppLogger.log('CONFIG DEBUG: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Clears the cached config (useful for testing or when config changes)
  static void clearCache() {
    _cachedConfig = null;
    AppLogger.log('CONFIG DEBUG: Cache cleared');
  }
}
