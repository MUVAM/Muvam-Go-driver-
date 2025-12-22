import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getEarningsSummary({
    required String period,
  }) async {
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/earnings/summary?period=$period';

    AppLogger.log('FETCHING EARNINGS SUMMARY');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: GET');
    AppLogger.log('Period: $period');
    AppLogger.log('Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Headers: ${response.headers}');
      AppLogger.log('Response Bodyyyy: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Success: ${data.toString().substring(0, min(200, data.toString().length))}',
        );
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getEarningsSummary: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('END FETCHING EARNINGS SUMMARY');
    }
  }

  Future<Map<String, dynamic>> getEarningsOverview({
    required String period,
  }) async {
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/earnings/overview?period=$period';

    AppLogger.log('FETCHING EARNINGS OVERVIEW');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: GET');
    AppLogger.log('Period: $period');
    AppLogger.log('Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Headers: ${response.headers}');
      AppLogger.log('Response Body++++++: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Success: ${data.toString().substring(0, min(200, data.toString().length))}',
        );
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getEarningsOverview: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('END FETCHING EARNINGS OVERVIEW');
    }
  }
}
