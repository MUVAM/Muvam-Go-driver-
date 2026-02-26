import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeleteAccountService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> deleteAccount(String reason) async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/users/delete';

    final requestBody = {'reason': reason};

    //==================================');
    //DELETING ACCOUNT');
    //==================================');
    //URL: $url');
    //Method: POST');
    //Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['error'] != null) {
          final errorMsg = data['message'] ?? data['error'];
          //Error in 200 response: $errorMsg');
          return {'success': false, 'message': errorMsg};
        }

        if (data['message'] != null) {
          //Account deleted successfully: ${data['message']}');

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');

          return {'success': true, 'message': data['message'], 'data': data};
        }

        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorMessage =
            data['message'] ?? data['error'] ?? 'Failed to delete account';

        AppLogger.log(
          'Failed with status ${response.statusCode}: $errorMessage',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      //Exception in deleteAccount: $e');
      return {
        'success': false,
        'message': 'Failed to delete account. Please try again.',
      };
    } finally {
      //==================================');
    }
  }
}
