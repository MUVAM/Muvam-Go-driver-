import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/url_constants.dart';

class ApiService {
  static const String baseUrl = UrlConstants.baseUrl;

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      print('Sending OTP to: $phoneNumber');
      print('URL: $baseUrl${UrlConstants.sendOtp}');
      
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.sendOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Phone': phoneNumber}),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.resendOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Phone': phoneNumber}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to resend OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      print('=== VERIFY OTP DEBUG ===');
      print('Phone: $phoneNumber');
      print('OTP: $otp');
      print('URL: $baseUrl${UrlConstants.verifyOtp}');
      
      final requestBody = {'Phone': phoneNumber, 'Code': otp};
      print('Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.verifyOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('SUCCESS: OTP verified');
        return {'success': true, 'data': data};
      } else {
        print('ERROR: OTP verification failed');
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? error['error'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      print('VERIFY OTP ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('=== END VERIFY OTP DEBUG ===\n');
    }
  }

  // Register User
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String city,
    required String location,
  }) async {
    try {
      print('=== REGISTER USER DEBUG ===');
      final requestBody = {
        'first_name': firstName,
        'middle_name': middleName ?? '',
        'last_name': lastName,
        'email': email,
        'Phone': phoneNumber,
        'date_of_birth': dateOfBirth,
        'city': city,
        'role': 'driver',
        'location': location,
      };
      print('Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.registerUser}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? error['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('REGISTER ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('=== END REGISTER USER DEBUG ===\n');
    }
  }

  // Upload verification documents
  static Future<Map<String, dynamic>> uploadVerificationDocuments({
    required File driverLicense,
    required File vehicleRegistration,
    required File insurance,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/verification'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(await http.MultipartFile.fromPath(
        'driver_license_file',
        driverLicense.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'vehicle_registration_file',
        vehicleRegistration.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'insurrance_file',
        insurance.path,
      ));

      print('=== UPLOAD DOCUMENTS DEBUG ===');
      print('URL: $baseUrl/users/verification');
      print('Token: $token');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(responseBody);
        return {'success': false, 'message': error['message'] ?? error['error'] ?? 'Upload failed'};
      }
    } catch (e) {
      print('UPLOAD ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('=== END UPLOAD DOCUMENTS DEBUG ===\n');
    }
  }
}