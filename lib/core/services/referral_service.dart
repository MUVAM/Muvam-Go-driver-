import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getReferralCode() async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/referrals';

    //FETCHING REFERRAL CODE');
    //URL: $url');
    //Method: POST');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //Referral code fetched successfully');
        //Code: ${data['code']}');
        //Share URL: ${data['share_url']}');
        //Total Uses: ${data['total_uses']}');
        return {'success': true, 'data': data};
      } else {
        //Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      //Exception in getReferralCode: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      //==================================');
    }
  }
}
