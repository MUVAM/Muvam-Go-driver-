import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    // Build request body - only include status
    final requestBody = <String, dynamic>{};
    if (status != null) requestBody['status'] = status;
    // Uncomment if pagination is needed later
    // if (limit != null) requestBody['limit'] = limit;
    // if (offset != null) requestBody['offset'] = offset;

    try {
      final response = await http.post(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rides}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    } finally {}
  }

  Future<Map<String, dynamic>> getRideDetails(int rideId) async {
    final token = await _getToken();

    if (token == null) {
      //No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}${UrlConstants.rides}/$rideId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Headers: ${response.headers}');
      //Response boyyyyy: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Success: ${data.toString().substring(0, min(200, data.toString().length))}',
        );
        return {'success': true, 'data': data};
      } else {
        //Failed: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      //Exception in getRideDetails: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      //END FETCHING RIDE DETAILS');
    }
  }

  Future<Map<String, dynamic>> getRidesByStatus(String status) async {
    return getRides(status: status);
  }

  Future<Map<String, dynamic>> getAllRides() async {
    return getRides();
  }

  Future<Map<String, dynamic>> getPrebookedRides() async {
    return getRides(status: 'prebooked');
  }

  Future<Map<String, dynamic>> getActiveRides() async {
    return getRides(status: 'active');
  }

  Future<Map<String, dynamic>> getHistoryRides() async {
    return getRides(status: 'history');
  }
}
