import 'dart:convert';
import 'package:muvam_rider/features/auth/data/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _lastLoginKey = 'last_login_time';

  Future<void> sendOtp(String phone) async {
    final result = await ApiService.sendOtp(phone);
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> resendOtp(String phone) async {
    final result = await ApiService.resendOtp(phone);
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to resend OTP');
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String code, String phone) async {
    final result = await ApiService.verifyOtp(phone, code);
    if (result['success'] == true) {
      final response = VerifyOtpResponse.fromJson(result['data']);
      await _saveToken(response.token);
      return response;
    } else {
      throw Exception(result['message'] ?? 'Invalid OTP');
    }
  }

  Future<RegisterUserResponse> registerUser(RegisterUserRequest request) async {
    final result = await ApiService.registerUser(
      firstName: request.firstName,
      middleName: request.middleName,
      lastName: request.lastName,
      email: request.email,
      phoneNumber: request.phoneNumber,
      dateOfBirth: request.dateOfBirth,
      city: request.city,
      location: request.location,
    );
    if (result['success'] == true) {
      final response = RegisterUserResponse.fromJson(result['data']);
      await _saveToken(response.token);
      return response;
    } else {
      throw Exception(result['message'] ?? 'Registration failed');
    }
  }

  Future<void> completeProfile(CompleteProfileRequest request) async {
    // Implementation for complete profile API call
    // This would call the complete profile endpoint
  }

  Future<void> saveUserData(
    String firstName,
    String lastName,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      return {
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'email': userData['email'],
      };
    }
    return {};
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_lastLoginKey);
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginString = prefs.getString(_lastLoginKey);

    if (lastLoginString == null) return true;

    final lastLogin = DateTime.parse(lastLoginString);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    return difference.inHours >= 2;
  }

  Future<void> updateLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }
}
