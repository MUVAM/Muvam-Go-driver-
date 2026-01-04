import 'package:cloud_firestore/cloud_firestore.dart';
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
          "project_id": "muvam-go",
          "private_key_id": "66741a64076de1cdf0f4b7103a6752cf501eca2c",
          "private_key":
              "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiGw0BAQEFAASCBKcwggSjAgEAAoIBAQCr1CM5SldLKXAX\nhEgHCHCXL/9rGfBkS8EPMYx64vz4XHB7IO9CpWMcorx8memX7XPYfYIoAshQFzJ1\nl9v5jjpPFSKR9C/h3FoZvWZkPYxUvwHRFUXROtY9gGPPSwX5miNgeyJTb+SWnYjf\neUEFk5Dj48hmART73jaw3AR/92BwegqHGcPclekXjPnWSuHNP/42R1NZ8C7aw0bY\nGZEp00VmdZnETeJzuw5Sz3hMos6xjdFiMVbZQcZP4d52Cdel++1wNpgi39ti+Wtg\nKSZiCf0n0ujM6j6k5D2n+T6/Vb0vzI+cQtqqSllfhOd0cHh6zhSEabhsI+3gUjM+\n++3NR9PHAgMBAAECggEAEQNjLXP/6rBCqgFuBExAoaed+aPK2pNpnTCBwVUiSREW\nDgr3xbiMdLRkR04SA/n942yh64ZDATMayuvrWu1LNrNYBe2QpCNmRHAtaDVz5Jw4\n+NPLYukZd2Nz/n1mLQ2m/RGUF4DXuFYGzGG8H2o6CWZvXDI1Oq8I6UAPrf/3a4tw\nWzp6lehCF8Ex4g3AnZuu874TRvu7L9KmbYW2xmNqUiP4yu5b9d8axVN7t/gFWXPl\n2V+Fc6OwdFIaGNW7Oq9SnMznNICmES9PymOBKhC3XZWuTBU7csKhPBbdlvQgzpSF\n9u+IGKGzDBcHwjrGRzBxTaLtGphwZPDt9GQJItctAQKBgQDYs+TbYNz6Va+YzrK1\nzWwHm1dlYFshifIEJnXlemjp2A/psOZkQAiHjI5MVHiryP6XV8VC6PpTDMjJB0/E\n+lKuVA07yqD/SiKgGR6SXUKGDivYoQnE0Bql1vc7Fv9YbI77s4a6LHRYhaoJ7XsW\nA2RwC/61ckZ+vkcCIRI6MEebRwKBgQDK/QgZRPhUvRRtkL3mgt+og57RGB4FPum1\n4pfIt6c+GoRYGmGUXVDl/jnfGatJoYmIqBhAKEFKyNsMt10VYFOgE56mQrX6/nh3\nfp3eKi8MLNL6KrY98b3gTLkzH+z9LMKMADBZc/EUY0LTYL+hv3Y/WnciKVfQDM5c\nqJW6cXlDgQKBgAV2Y2p0Qp280zRS4YZbq0F11PolN6bcx1D7dzVVpJdgbuZBI02b\nn5trG5so9fG+m0xNVhedr9GwHM+Uc5pPhQ4H6F19ehl1UPIgL/kYiLjAWrKXPJvN\ncx6DELBYoA8mjWQi3l6LCFPC6spdRiED7OA2LTF9s/E18qxHESKOXP+5AoGBAK6X\nnsylTvcLvrNSqJPJA3ic5RAxrziR2VExOZ5RoI7BHg3tevqynK+Fz9795B8ryvD4\nrAsa1LXvNsGkQXLubF8mIPIeNQpSr+kPxddd7yOItlqoPCHheJChTTYVArDsO9VR\nIEUAfV4s1kCbWZhU5u8s74U5jCcNrL1z330CtuuBAoGAU6yRtmh4Y8GVHzjRmJE5\nouRFEY//CWpPnBbOERNuSPAWiiJdQBWJthBCR+yMJlM/h2qhg2/TwXUGVnu5BskH\ngMzm/9v8kniEnwQRiWcUNn0/c2pL7cFBs8t54iyHYGXR068IcifUhN6ZiA+92Wv/\naeSQoFkq+bAfujZF3MSOXXg=\n-----END PRIVATE KEY-----\n",
          "client_email":
              "firebase-adminsdk-fbsvc@muvam-go.iam.gserviceaccount.com",
          "client_id": "103593346923649190493",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url":
              "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40muvam-go.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com",
        };

        AppLogger.log(
          'CONFIG DEBUG: Service account config created and cached',
        );
        final privateKey = _cachedConfig!["private_key"] as String;
        AppLogger.log(
          'CONFIG DEBUG: Has private_key: ${privateKey.isNotEmpty}',
        );
        AppLogger.log('CONFIG DEBUG: Private key length: ${privateKey.length}');
        AppLogger.log(
          'CONFIG DEBUG: Private key starts with: ${privateKey.length > 30 ? privateKey.substring(0, 30) : privateKey}...',
        );
        AppLogger.log(
          'CONFIG DEBUG: Private key ends with: ${privateKey.length > 30 ? '...' + privateKey.substring(privateKey.length - 30) : privateKey}',
        );
        AppLogger.log(
          'CONFIG DEBUG: Has BEGIN marker: ${privateKey.contains('-----BEGIN')}',
        );
        AppLogger.log(
          'CONFIG DEBUG: Has END marker: ${privateKey.contains('-----END')}',
        );
        AppLogger.log(
          'CONFIG DEBUG: Has private_key_id: ${(_cachedConfig!["private_key_id"] as String).isNotEmpty}',
        );
        AppLogger.log(
          'CONFIG DEBUG: Has client_id: ${(_cachedConfig!["client_id"] as String).isNotEmpty}',
        );

        return _cachedConfig!;
      } else {
        AppLogger.log(
          'CONFIG DEBUG: Admin document does not exist or has no data',
        );
      }
    } catch (e) {
      AppLogger.log('CONFIG DEBUG: Error fetching Firebase config: $e');
      AppLogger.log('CONFIG DEBUG: Stack trace: ${StackTrace.current}');
    }

    AppLogger.log(
      'CONFIG DEBUG: Falling back to minimal config (this will cause auth issues)',
    );
    AppLogger.log(
      'CONFIG DEBUG: NOTIFICATIONS WILL NOT WORK WITHOUT PROPER SERVICE ACCOUNT CONFIG',
    );
    // Return minimal config if Firestore fetch fails
    return {
      "type": "service_account",
      "project_id": "muvam-go",
      "private_key_id": "66741a64076de1cdf0f4b7103a6752cf501eca2c",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiGw0BAQEFAASCBKcwggSjAgEAAoIBAQCr1CM5SldLKXAX\nhEgHCHCXL/9rGfBkS8EPMYx64vz4XHB7IO9CpWMcorx8memX7XPYfYIoAshQFzJ1\nl9v5jjpPFSKR9C/h3FoZvWZkPYxUvwHRFUXROtY9gGPPSwX5miNgeyJTb+SWnYjf\neUEFk5Dj48hmART73jaw3AR/92BwegqHGcPclekXjPnWSuHNP/42R1NZ8C7aw0bY\nGZEp00VmdZnETeJzuw5Sz3hMos6xjdFiMVbZQcZP4d52Cdel++1wNpgi39ti+Wtg\nKSZiCf0n0ujM6j6k5D2n+T6/Vb0vzI+cQtqqSllfhOd0cHh6zhSEabhsI+3gUjM+\n++3NR9PHAgMBAAECggEAEQNjLXP/6rBCqgFuBExAoaed+aPK2pNpnTCBwVUiSREW\nDgr3xbiMdLRkR04SA/n942yh64ZDATMayuvrWu1LNrNYBe2QpCNmRHAtaDVz5Jw4\n+NPLYukZd2Nz/n1mLQ2m/RGUF4DXuFYGzGG8H2o6CWZvXDI1Oq8I6UAPrf/3a4tw\nWzp6lehCF8Ex4g3AnZuu874TRvu7L9KmbYW2xmNqUiP4yu5b9d8axVN7t/gFWXPl\n2V+Fc6OwdFIaGNW7Oq9SnMznNICmES9PymOBKhC3XZWuTBU7csKhPBbdlvQgzpSF\n9u+IGKGzDBcHwjrGRzBxTaLtGphwZPDt9GQJItctAQKBgQDYs+TbYNz6Va+YzrK1\nzWwHm1dlYFshifIEJnXlemjp2A/psOZkQAiHjI5MVHiryP6XV8VC6PpTDMjJB0/E\n+lKuVA07yqD/SiKgGR6SXUKGDivYoQnE0Bql1vc7Fv9YbI77s4a6LHRYhaoJ7XsW\nA2RwC/61ckZ+vkcCIRI6MEebRwKBgQDK/QgZRPhUvRRtkL3mgt+og57RGB4FPum1\n4pfIt6c+GoRYGmGUXVDl/jnfGatJoYmIqBhAKEFKyNsMt10VYFOgE56mQrX6/nh3\nfp3eKi8MLNL6KrY98b3gTLkzH+z9LMKMADBZc/EUY0LTYL/hv3Y/WnciKVfQDM5c\nqJW6cXlDgQKBgAV2Y2p0Qp280zRS4YZbq0F11PolN6bcx1D7dzVVpJdgbuZBI02b\nn5trG5so9fG+m0xNVhedr9GwHM+Uc5pPhQ4H6F19ehl1UPIgL/kYiLjAWrKXPJvN\ncx6DELBYoA8mjWQi3l6LCFPC6spdRiED7OA2LTF9s/E18qxHESKOXP+5AoGBAK6X\nnsylTvcLvrNSqJPJA3ic5RAxrziR2VExOZ5RoI7BHg3tevqynK+Fz9795B8ryvD4\nrAsa1LXvNsGkQXLubF8mIPIeNQpSr+kPxddd7yOItlqoPCHheJChTTYVArDsO9VR\nIEUAfV4s1kCbWZhU5u8s74U5jCcNrL1z330CtuuBAoGAU6yRtmh4Y8GVHzjRmJE5\nouRFEY//CWpPnBbOERNuSPAWiiJdQBWJthBCR+yMJlM/h2qhg2/TwXUGVnu5BskH\ngMzm/9v8kniEnwQRiWcUNn0/c2pL7cFBs8t54iyHYGXR068IcifUhN6ZiA+92Wv/\naeSQoFkq+bAfujZF3MSOXXg=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@muvam-go.iam.gserviceaccount.com",
      "client_id": "103593346923649190493",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40muvam-go.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };
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
