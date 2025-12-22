import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/earnings_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/analytics/data/models/earning_over_view_model.dart';
import 'package:muvam_rider/features/analytics/data/models/earnings_summary_model.dart';

class EarningsProvider extends ChangeNotifier {
  final EarningsService _earningsService = EarningsService();

  EarningsSummary? _earningsSummary;
  WeeklyOverviewData? _weeklyOverview;

  bool _isLoading = false;
  bool _isLoadingOverview = false;
  String? _errorMessage;

  // Getters
  EarningsSummary? get earningsSummary => _earningsSummary;
  WeeklyOverviewData? get weeklyOverview => _weeklyOverview;
  bool get isLoading => _isLoading;
  bool get isLoadingOverview => _isLoadingOverview;
  String? get errorMessage => _errorMessage;

  /// Fetch earnings summary from /earnings/summary endpoint
  Future<void> fetchEarningsSummary(String period) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching earnings summary for period: $period');

      final result = await _earningsService.getEarningsSummary(period: period);

      if (result['success'] == true && result['data'] != null) {
        final summaryData = result['data']['summary'];
        if (summaryData != null) {
          _earningsSummary = EarningsSummary.fromJson(summaryData);
          _errorMessage = null;
          AppLogger.log('Earnings summary fetched successfully');
        } else {
          _errorMessage = 'No summary data available';
          _earningsSummary = null;
          AppLogger.log('No summary data in response');
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch earnings summary';
        _earningsSummary = null;
        AppLogger.log('Failed to fetch earnings summary: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error fetching earnings summary: $e';
      AppLogger.log('Exception in fetchEarningsSummary: $e');
      _earningsSummary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch weekly overview data from /earnings/overview endpoint for chart
  Future<void> fetchWeeklyOverview(String period) async {
    _isLoadingOverview = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching weekly overview for period: $period');

      final result = await _earningsService.getWeeklyOverview(period: period);

      if (result['success'] == true && result['data'] != null) {
        _weeklyOverview = WeeklyOverviewData.fromJson(result['data']);
        _errorMessage = null;
        AppLogger.log(
          'Weekly overview fetched successfully: ${_weeklyOverview?.dailyBreakdown.length} days',
        );
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch weekly overview';
        _weeklyOverview = null;
        AppLogger.log('Failed to fetch weekly overview: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error fetching weekly overview: $e';
      AppLogger.log('Exception in fetchWeeklyOverview: $e');
      _weeklyOverview = null;
    } finally {
      _isLoadingOverview = false;
      notifyListeners();
    }
  }

  /// Format price with # symbol instead of ₦
  String formatPrice(double price) {
    if (price >= 1000) {
      // Format with comma separator for thousands
      final formatter = price.toStringAsFixed(0);
      final parts = <String>[];
      var str = formatter;
      while (str.length > 3) {
        parts.insert(0, str.substring(str.length - 3));
        str = str.substring(0, str.length - 3);
      }
      parts.insert(0, str);
      return '#${parts.join(',')}';
    }
    return '#${price.toStringAsFixed(0)}';
  }

  /// Format hours and minutes to decimal format
  String formatHours(int hours, int minutes) {
    if (hours > 0 && minutes > 0) {
      return '$hours.${(minutes / 60 * 10).toInt()}';
    } else if (hours > 0) {
      return '$hours';
    } else if (minutes > 0) {
      return '0.${(minutes / 60 * 10).toInt()}';
    }
    return '0';
  }

  /// Convert tab index to period string
  String getPeriodFromIndex(int index) {
    switch (index) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      case 2:
        return 'monthly';
      default:
        return 'daily';
    }
  }

  /// Clear all data
  void clearData() {
    _earningsSummary = null;
    _weeklyOverview = null;
    _errorMessage = null;
    notifyListeners();
  }
}
