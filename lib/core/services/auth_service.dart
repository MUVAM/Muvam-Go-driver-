import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.sendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    AppLogger.log('Response Status Code----: ${response.statusCode}');
    AppLogger.log('Response Body++++: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.resendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to resend OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String code, String phone) async {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.verifyOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'phone': phone}),
    );

    AppLogger.log('Response Status Code-------: ${response.statusCode}');
    AppLogger.log('Response Body++++++: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      log('Response Status Codedjkdhe: ${response.statusCode}');
      log('Response Bodyuuuuu: ${response.body}');

      // Handle the new token structure
      if (result['token'] != null) {
        final tokenData = result['token'];
        if (tokenData is Map<String, dynamic>) {
          // New structure: token is an object with access_token, refresh_token, expires_in
          final accessToken = tokenData['access_token'];
          final refreshToken = tokenData['refresh_token'];
          final expiresIn = tokenData['expires_in'];

          if (accessToken != null) {
            await _saveToken(accessToken);
          }
          if (refreshToken != null) {
            await _saveRefreshToken(refreshToken);
          }
          if (expiresIn != null) {
            await _saveTokenExpiry(expiresIn);
          }

          AppLogger.log('✅ Saved access_token: $accessToken', tag: 'AUTH');
          AppLogger.log('✅ Saved refresh_token: $refreshToken', tag: 'AUTH');
          AppLogger.log(
            '⏰ Access token expires in: $expiresIn seconds (1 hour)',
            tag: 'AUTH',
          );

          final expiryTime =
              DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(
            expiryTime.toInt(),
          );
          AppLogger.log('📅 Token will expire at: $expiryDate', tag: 'AUTH');
        } else {
          // Old structure: token is a string
          await _saveToken(tokenData.toString());
        }
      }

      // Store user data after successful OTP verification
      if (result['user'] != null) {
        final user = result['user'];
        await _saveUserInfo(
          userId: user['ID']?.toString(),
          firstName: user['first_name']?.toString(),
          lastName: user['last_name']?.toString(),
          profilePhoto: user['profile_photo']?.toString(),
        );
      }

      // Save vehicle_submitted status
      final prefs = await SharedPreferences.getInstance();
      final vehicleSubmitted = result['vehicle_submitted'] ?? false;
      await prefs.setBool('vehicle_submitted', vehicleSubmitted);

      AppLogger.log('📊 Backend vehicle_submitted value: $vehicleSubmitted');
      AppLogger.log('✅ vehicle_submitted saved to SharedPreferences');

      // Verify it was saved
      final savedValue = prefs.getBool('vehicle_submitted');
      AppLogger.log('🔍 Immediate verification: $savedValue');

      return result;
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.registerUser}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register user');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> _saveTokenExpiry(int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    // Access token expires in 1 hour (3600 seconds)
    final expiryTime =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  Future<void> saveToken(String token) async {
    await _saveToken(token);
    // Default to 1 hour expiry if not provided
    final expiryTime = DateTime.now().millisecondsSinceEpoch + (3600 * 1000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  Future<dynamic?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // Safely read expiry — handle legacy String value stored by old code
    int? expiryTime;
    try {
      expiryTime = prefs.getInt(_tokenExpiryKey);
    } catch (e) {
      // Old code saved a String here — clear it and treat as no expiry
      AppLogger.log('⚠️ Corrupt expiry value found, clearing...', tag: 'AUTH');
      await prefs.remove(_tokenExpiryKey);
      expiryTime = null;
    }

    if (token == null) {
      AppLogger.log('❌ No token found', tag: 'AUTH');
      return null;
    }

    if (expiryTime != null) {
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      final int bufferTime = 5 * 60 * 1000;

      if (currentTime >= expiryTime) {
        AppLogger.log(
          '⚠️ Token has expired, attempting refresh...',
          tag: 'AUTH',
        );
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        } else {
          AppLogger.log('❌ Token refresh failed, clearing tokens', tag: 'AUTH');
          await clearToken();
          return null;
        }
      }

      if (currentTime >= (expiryTime - bufferTime)) {
        AppLogger.log('🔄 Token expiring soon, refreshing...', tag: 'AUTH');
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        }
      }

      final remainingTime = (expiryTime - currentTime) / 1000 / 60;
      AppLogger.log(
        '✅ Token valid for: ${remainingTime.toStringAsFixed(1)} minutes',
        tag: 'AUTH',
      );
    }

    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

 Future<bool> refreshToken() async {
  try {
    final refreshToken = await getRefreshToken();
    final token = await _getToken();
    log("this is the refresh token $refreshToken");
    if (refreshToken == null) {
      AppLogger.log('❌ No refresh token available', tag: 'AUTH');
      return false;
    }

    AppLogger.log('🔄 Attempting to refresh token...', tag: 'AUTH');

    final response = await http
        .post(
          Uri.parse('${UrlConstants.baseUrl}${UrlConstants.refreshToken}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Token refresh request timed out');
          },
        );

    AppLogger.log('📡 Refresh response status: ${response.statusCode}', tag: 'AUTH');
    AppLogger.log('📄 Refresh response body: ${response.body}', tag: 'AUTH');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Backend returns { "access_token": { "access_token": "...", "refresh_token": "...", "expires_in": 3600 } }
      final tokenWrapper = responseData['access_token'];

      if (tokenWrapper != null && tokenWrapper is Map<String, dynamic>) {
        final accessToken = tokenWrapper['access_token'];
        final newRefreshToken = tokenWrapper['refresh_token'];
        final expiresIn = tokenWrapper['expires_in'];

        if (accessToken != null) {
          await _saveToken(accessToken);
          AppLogger.log('✅ New access token saved', tag: 'AUTH');
        }
        if (newRefreshToken != null) {
          await _saveRefreshToken(newRefreshToken);
          AppLogger.log('✅ New refresh token saved', tag: 'AUTH');
        }
        if (expiresIn != null) {
          await _saveTokenExpiry(expiresIn);
          AppLogger.log('✅ Token expiry saved: $expiresIn seconds', tag: 'AUTH');
        }

        AppLogger.log('✅ Token refreshed successfully!', tag: 'AUTH');
        return true;
      }

      AppLogger.log('❌ Invalid response structure: $responseData', tag: 'AUTH');
      return false;
    } else {
      AppLogger.log('❌ Token refresh failed: ${response.body}', tag: 'AUTH');
      return false;
    }
  } catch (e) {
    AppLogger.log('❌ Token refresh error: $e', tag: 'AUTH');
    return false;
  }
}
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    AppLogger.log('🗑️ All tokens cleared', tag: 'AUTH');
  }

  Future<Map<String, dynamic>> completeProfile(
    Map<String, dynamic> profileData,
  ) async {
    final token = await getToken();
    final uri = Uri.parse(
      '${UrlConstants.baseUrl}${UrlConstants.completeProfile}',
    );
    final multipartRequest = http.MultipartRequest('POST', uri);

    multipartRequest.headers['Authorization'] = 'Bearer $token';
    profileData.forEach((key, value) {
      if (value != null && key != 'profile_photo') {
        multipartRequest.fields[key] = value.toString();
      }
    });

    if (profileData['profile_photo'] != null) {
      final file = File(profileData['profile_photo']);
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('profile_photo', file.path),
      );
    }

    final response = await multipartRequest.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to complete profile');
    }
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    final isValid = token != null;
    AppLogger.log('🔐 Token validity check: $isValid', tag: 'AUTH');
    return isValid;
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    int? expiryTime;
    try {
      expiryTime = prefs.getInt(_tokenExpiryKey);
    } catch (e) {
      await prefs.remove(_tokenExpiryKey);
      return true;
    }

    if (expiryTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      return currentTime >= expiryTime;
    }

    return true;
  }

  Future<bool> isTokenExpired() async {
    return await isSessionExpired();
  }

  Future<void> updateLastLoginTime() async {
    // This is now handled by token expiry
  }

  Future<void> _saveUserInfo({
    String? userId,
    String? firstName,
    String? lastName,
    String? profilePhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString('user_id', userId);
    if (firstName != null) await prefs.setString('first_name', firstName);
    if (lastName != null) await prefs.setString('last_name', lastName);
    if (profilePhoto != null)
      await prefs.setString('profile_photo', profilePhoto);
  }

  Future<void> saveUserData(
    String firstName,
    String lastName,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', firstName);
    await prefs.setString('last_name', lastName);
    await prefs.setString('email', email);
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString('user_id'),
      'first_name': prefs.getString('first_name'),
      'last_name': prefs.getString('last_name'),
      'email': prefs.getString('email'),
      'profile_photo': prefs.getString('profile_photo'),
    };
  }
}
