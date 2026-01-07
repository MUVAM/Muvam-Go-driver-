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
      AppLogger.log('CONFIG DEBUG: Loading service account from .env file');

      // Load from FirebaseServiceAccount (which reads from .env)
      _cachedConfig = Map<String, dynamic>.from(
        FirebaseServiceAccount.credentials,
      );

      AppLogger.log('CONFIG DEBUG: Service account config loaded and cached');

      // Validate the config
      final privateKey = _cachedConfig!["private_key"] as String;
      final projectId = _cachedConfig!["project_id"] as String;
      final clientEmail = _cachedConfig!["client_email"] as String;
      final privateKeyId = _cachedConfig!["private_key_id"] as String;

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
      AppLogger.log(
        'CONFIG DEBUG: Has private_key_id: ${privateKeyId.isNotEmpty}',
      );

      // Validate that credentials are properly loaded from .env
      if (privateKey.isEmpty ||
          !privateKey.contains('-----BEGIN PRIVATE KEY-----') ||
          !privateKey.contains('-----END PRIVATE KEY-----')) {
        AppLogger.log('CONFIG DEBUG: Invalid or missing private key!');
        throw Exception(
          'Firebase private key is invalid or not found in .env file. '
          'Please ensure FIREBASE_PRIVATE_KEY is set correctly in your .env file.',
        );
      }

      if (projectId.isEmpty) {
        AppLogger.log('CONFIG DEBUG: Project ID is missing!');
        throw Exception(
          'Firebase project ID not found in .env file. '
          'Please ensure FIREBASE_PROJECT_ID is set in your .env file.',
        );
      }

      if (clientEmail.isEmpty || !clientEmail.contains('@')) {
        AppLogger.log('CONFIG DEBUG: Client email is invalid!');
        throw Exception(
          'Firebase client email is invalid or not found in .env file. '
          'Please ensure FIREBASE_CLIENT_EMAIL is set correctly in your .env file.',
        );
      }

      // Check for placeholder values in .env
      if (privateKey.contains('YOUR_PRIVATE_KEY_HERE') ||
          privateKey.contains('paste_from_json') ||
          clientEmail.contains('YOUR_CLIENT_EMAIL_HERE')) {
        AppLogger.log('CONFIG DEBUG: .env contains placeholder values!');
        throw Exception(
          'Firebase credentials in .env file contain placeholder values. '
          'Please update your .env file with actual credentials from Firebase Console.',
        );
      }

      AppLogger.log('CONFIG DEBUG: ✓ All credential validations passed');
      AppLogger.log(
        'CONFIG DEBUG: ✓ Firebase service account loaded successfully from .env',
      );

      return _cachedConfig!;
    } on Exception catch (e) {
      AppLogger.log('CONFIG DEBUG: Error loading Firebase config: $e');
      AppLogger.log('CONFIG DEBUG: Stack trace: ${StackTrace.current}');

      // Provide helpful guidance based on error type
      if (e.toString().contains('Environment variables not loaded')) {
        AppLogger.log(
          'CONFIG DEBUG: SOLUTION: Ensure await dotenv.load() is called in main.dart',
        );
      } else if (e.toString().contains('not found in .env')) {
        AppLogger.log(
          'CONFIG DEBUG: SOLUTION: Check that .env file exists in project root and contains all required Firebase variables',
        );
      } else if (e.toString().contains('.env file')) {
        AppLogger.log(
          'CONFIG DEBUG: SOLUTION: Verify .env file format and Firebase credential values',
        );
      }

      rethrow;
    } catch (e) {
      AppLogger.log('CONFIG DEBUG: Unexpected error: $e');
      AppLogger.log('CONFIG DEBUG: Stack trace: ${StackTrace.current}');

      throw Exception(
        'Failed to load Firebase configuration. '
        'Please ensure .env file is properly configured. Error: $e',
      );
    }
  }

  static void clearCache() {
    _cachedConfig = null;
    AppLogger.log('CONFIG DEBUG: Cache cleared');
  }
}
