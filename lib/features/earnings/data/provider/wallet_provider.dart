import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/wallet_service.dart';
import 'package:muvam_rider/features/earnings/data/models/wallet_models.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();

  bool _isLoading = false;
  String? _errorMessage;
  WalletSummaryResponse? _walletSummary;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WalletSummaryResponse? get walletSummary => _walletSummary;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Fetch wallet summary from the API
  Future<bool> fetchWalletSummary() async {
    _setLoading(true);
    _setError(null);

    try {
      _walletSummary = await _walletService.getWalletSummary();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Format amount with commas (e.g., ₦120,000)
  String formatAmount(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // Format date-time into readable format
  String formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dt.month - 1];
      final day = dt.day;
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, $year • $hour:$minute $period';
    } catch (e) {
      return dateTime;
    }
  }

  // Clear any error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
