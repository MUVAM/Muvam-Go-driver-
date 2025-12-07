import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

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
      if (result['token'] != null) {
        await _saveToken(result['token']);
      }
      return result;
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
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
    await prefs.setString('last_login_time', DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> completeProfile(Map<String, dynamic> profileData) async {
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

  Future<void> updateLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_time', DateTime.now().millisecondsSinceEpoch.toString());
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
      'first_name': prefs.getString('first_name'),
      'last_name': prefs.getString('last_name'),
      'email': prefs.getString('email'),
    };
  }
}
