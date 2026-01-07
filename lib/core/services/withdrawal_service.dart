import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/earnings/data/models/bank.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WithdrawalService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Bank>> getBanks() async {
    final token = await _getToken();

    final url = '${UrlConstants.baseUrl}/wallet/banks';

    AppLogger.log('Getting banks: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Banks response: ${response.statusCode}');
    AppLogger.log('Banks body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<dynamic> jsonList = [];

      // Handle nested data structure: {"data":{"data":[...]}}
      if (responseData is Map) {
        if (responseData['data'] != null) {
          if (responseData['data'] is Map &&
              responseData['data']['data'] != null) {
            jsonList = responseData['data']['data'];
          } else if (responseData['data'] is List) {
            jsonList = responseData['data'];
          }
        } else if (responseData['banks'] != null) {
          jsonList = responseData['banks'];
        }
      } else if (responseData is List) {
        jsonList = responseData;
      }

      AppLogger.log('Banks count: ${jsonList.length}');
      return jsonList.map((json) => Bank.fromJson(json)).toList();
    } else {
      AppLogger.log('Failed to fetch banks: ${response.body}');
      throw Exception('Failed to fetch banks');
    }
  }

  Future<Map<String, dynamic>> withdrawFunds({
    required String accountName,
    required String accountNumber,
    required String bankName,
    required String bankCode,
    required double amount,
  }) async {
    final token = await _getToken();

    final url = '${UrlConstants.baseUrl}/wallet/withdraw';

    AppLogger.log('Withdrawing funds: $url');

    final body = {
      'account_name': accountName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'bank_code': bankCode,
      'amount': amount,
    };

    AppLogger.log('Withdrawal payload: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    AppLogger.log('Withdrawal response: ${response.statusCode}');
    AppLogger.log('Withdrawal body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to withdraw funds';
      AppLogger.log('Failed to withdraw: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}
