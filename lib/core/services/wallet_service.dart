import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/earnings/data/models/wallet_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<WalletSummaryResponse> getWalletSummary() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.walletSummary}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    AppLogger.log('response===:${response.body}');

    if (response.statusCode == 200) {
      AppLogger.log('response++++++:${response.body}');
      final jsonResponse = jsonDecode(response.body);
      return WalletSummaryResponse.fromJson(jsonResponse);
    } else {
      AppLogger.log('errorrrrr-------:$response');
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to fetch wallet summary');
    }
  }
}
