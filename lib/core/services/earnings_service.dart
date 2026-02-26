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
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/earnings/summary?period=$period';

    //FETCHING EARNINGS SUMMARY');
    //URL: $url');
    //Period: $period');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body++++++++: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //Earnings summary fetched successfully');
        return {'success': true, 'data': data};
      } else {
        //Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      //Exception in getEarningsSummary: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      //==================================');
    }
  }

  Future<Map<String, dynamic>> getEarningsOverview({
    required String period,
  }) async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/earnings/overview?period=$period';

    //FETCHING EARNINGS OVERVIEW');
    //URL: $url');
    //Period: $period');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Bodyyyyyyy: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //Overview fetched successfully');

        // Log daily breakdown count
        final overview = data['overview'];
        if (overview != null && overview['daily_breakdown'] != null) {
          AppLogger.log(
            'Daily breakdown count: ${overview['daily_breakdown'].length}',
          );
        }

        return {'success': true, 'data': data};
      } else {
        //Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      //Exception in getEarningsOverview: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      //==================================');
    }
  }

  Future<Map<String, dynamic>> getEarningsBreakdown({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url =
        '${UrlConstants.baseUrl}/earnings/breakdown?start_date=$startDate&end_date=$endDate';

    //FETCHING EARNINGS BREAKDOWN');
    //URL: $url');

    try {
      final response = await http.get(
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
        //Earnings breakdown fetched successfully');
        return {'success': true, 'data': data};
      } else {
        //Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      //Exception in getEarningsBreakdown: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      //==================================');
    }
  }
}
