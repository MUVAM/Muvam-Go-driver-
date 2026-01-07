import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      // Try to load from environment variables first (recommended for security)
      if (dotenv.env['FIREBASE_PRIVATE_KEY'] != null) {
        AppLogger.log(
          'CONFIG DEBUG: Loading config from environment variables',
        );
        _cachedConfig = _getConfigFromEnv();

        if (_cachedConfig != null && _validateConfig(_cachedConfig!)) {
          AppLogger.log('CONFIG DEBUG: Successfully loaded from environment');
          return _cachedConfig!;
        }
      }

      // Fallback to Firestore (for runtime configuration)
      AppLogger.log(
        'CONFIG DEBUG: Fetching config from Firestore Admin/Admin document',
      );
      final doc = await FirebaseFirestore.instance
          .collection('Admin')
          .doc('Admin')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        AppLogger.log(
          'CONFIG DEBUG: Admin document found, extracting service account data',
        );

        final rawPrivateKey = data["private_key"] ?? "";
        final formattedPrivateKey = _formatPrivateKey(rawPrivateKey);

        _cachedConfig = {
          "type": "service_account",
          "project_id": data["project_id"] ?? "muvam-go",
          "private_key_id": data["private_key_id"] ?? "",
          "private_key": formattedPrivateKey,
          "client_email": data["client_email"] ?? "",
          "client_id": data["client_id"] ?? "",
          "auth_uri":
              data["auth_uri"] ?? "https://accounts.google.com/o/oauth2/auth",
          "token_uri":
              data["token_uri"] ?? "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              data["auth_provider_x509_cert_url"] ??
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": data["client_x509_cert_url"] ?? "",
          "universe_domain": data["universe_domain"] ?? "googleapis.com",
        };

        if (_validateConfig(_cachedConfig!)) {
          AppLogger.log(
            'CONFIG DEBUG: Service account config loaded from Firestore',
          );
          return _cachedConfig!;
        }
      }
    } catch (e) {
      AppLogger.log('CONFIG DEBUG: Error fetching Firebase config: $e');
      AppLogger.log('CONFIG DEBUG: Stack trace: ${StackTrace.current}');
    }

    AppLogger.log('CONFIG DEBUG: Failed to load valid config from any source');
    throw Exception(
      'Firebase service account configuration not found. '
      'Please set environment variables or configure Firestore Admin document.',
    );
  }

  /// Load configuration from environment variables
  static Map<String, dynamic>? _getConfigFromEnv() {
    try {
      final privateKey = dotenv.env['FIREBASE_PRIVATE_KEY'];
      if (privateKey == null || privateKey.isEmpty) {
        return null;
      }

      return {
        "type": "service_account",
        "project_id": dotenv.env['FIREBASE_PROJECT_ID'] ?? "muvam-go",
        "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'] ?? "",
        "private_key": _formatPrivateKey(privateKey),
        "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'] ?? "",
        "client_id": dotenv.env['FIREBASE_CLIENT_ID'] ?? "",
        "auth_uri":
            dotenv.env['FIREBASE_AUTH_URI'] ??
            "https://accounts.google.com/o/oauth2/auth",
        "token_uri":
            dotenv.env['FIREBASE_TOKEN_URI'] ??
            "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            dotenv.env['FIREBASE_AUTH_PROVIDER_CERT_URL'] ??
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_CERT_URL'] ?? "",
        "universe_domain":
            dotenv.env['FIREBASE_UNIVERSE_DOMAIN'] ?? "googleapis.com",
      };
    } catch (e) {
      AppLogger.log('CONFIG DEBUG: Error loading from environment: $e');
      return null;
    }
  }

  /// Validates that the config has all required fields
  static bool _validateConfig(Map<String, dynamic> config) {
    final requiredFields = [
      'project_id',
      'private_key',
      'client_email',
      'private_key_id',
    ];

    for (final field in requiredFields) {
      if (!config.containsKey(field) || (config[field] as String).isEmpty) {
        AppLogger.log('CONFIG DEBUG: Missing or empty field: $field');
        return false;
      }
    }

    final privateKey = config['private_key'] as String;
    if (!privateKey.contains('BEGIN PRIVATE KEY') ||
        !privateKey.contains('END PRIVATE KEY')) {
      AppLogger.log('CONFIG DEBUG: Invalid private key format');
      return false;
    }

    AppLogger.log('CONFIG DEBUG: Config validation passed');
    return true;
  }

  /// Formats private key to ensure proper PEM format
  static String _formatPrivateKey(String privateKey) {
    if (privateKey.isEmpty) {
      AppLogger.log('CONFIG DEBUG: Private key is empty');
      return privateKey;
    }

    // Remove any existing formatting and whitespace
    String cleanKey = privateKey
        .replaceAll('\\n', '\n')
        .replaceAll('\r', '')
        .trim();

    AppLogger.log('CONFIG DEBUG: Original key length: ${privateKey.length}');
    AppLogger.log('CONFIG DEBUG: Cleaned key length: ${cleanKey.length}');

    // Check if it already has proper PEM format
    if (cleanKey.startsWith('-----BEGIN PRIVATE KEY-----') &&
        cleanKey.endsWith('-----END PRIVATE KEY-----')) {
      AppLogger.log('CONFIG DEBUG: Private key already has proper PEM format');
      return cleanKey;
    }

    // Remove existing headers/footers if present
    cleanKey = cleanKey
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .trim();

    if (cleanKey.isEmpty) {
      AppLogger.log('CONFIG DEBUG: Private key is empty after cleaning');
      return '';
    }

    // Format as proper PEM
    final formattedKey =
        '-----BEGIN PRIVATE KEY-----\n' +
        _insertLineBreaks(cleanKey, 64) +
        '\n-----END PRIVATE KEY-----';

    AppLogger.log('CONFIG DEBUG: Private key formatted to proper PEM format');
    AppLogger.log('CONFIG DEBUG: Formatted key length: ${formattedKey.length}');

    return formattedKey;
  }

  /// Inserts line breaks every n characters
  static String _insertLineBreaks(String text, int lineLength) {
    if (text.length <= lineLength) return text;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += lineLength) {
      final end = (i + lineLength < text.length) ? i + lineLength : text.length;
      buffer.write(text.substring(i, end));
      if (end < text.length) buffer.write('\n');
    }
    return buffer.toString();
  }

  /// Clears the cached config (useful for testing or when config changes)
  static void clearCache() {
    _cachedConfig = null;
  }
}
