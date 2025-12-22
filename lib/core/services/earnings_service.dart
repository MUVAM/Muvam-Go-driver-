import 'dart:convert';
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

    AppLogger.log('==================================');
    AppLogger.log('FETCHING EARNINGS SUMMARY');
    AppLogger.log('==================================');
    AppLogger.log('URL: $url');
    AppLogger.log('Period: $period');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body++++++++: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log('Earnings summary fetched successfully');
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getEarningsSummary: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('==================================');
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

    AppLogger.log('==================================');
    AppLogger.log('FETCHING EARNINGS OVERVIEW');
    AppLogger.log('==================================');
    AppLogger.log('URL: $url');
    AppLogger.log('Period: $period');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Bodyyyyyyy: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log('Overview fetched successfully');

        // Log daily breakdown count
        final overview = data['overview'];
        if (overview != null && overview['daily_breakdown'] != null) {
          AppLogger.log(
            'Daily breakdown count: ${overview['daily_breakdown'].length}',
          );
        }

        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getEarningsOverview: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('==================================');
    }
  }
}
