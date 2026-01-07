import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

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
    await prefs.setString(
      'last_login_time',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> _saveTokenExpiry(int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await prefs.setString(_tokenExpiryKey, expiryTime.toString());
  }

  Future<void> saveToken(String token) async {
    await _saveToken(token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
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
    return token != null && token.isNotEmpty;
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginString = prefs.getString('last_login_time');
    if (lastLoginString == null) return true;

    final lastLogin = int.tryParse(lastLoginString) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceLogin = (now - lastLogin) / (1000 * 60 * 60);
    return hoursSinceLogin > 2; // 2 hours session
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);

    if (expiryString == null) {
      // If no expiry time is stored, fall back to session check
      return await isSessionExpired();
    }

    final expiryTime = int.tryParse(expiryString) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Consider token expired if less than 5 minutes remaining (300000 ms)
    return now >= (expiryTime - 300000);
  }

  Future<void> updateLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_login_time',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
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
