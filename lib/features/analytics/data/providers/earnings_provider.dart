import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/services/earnings_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/analytics/data/models/earnings_summary_model.dart';
import 'package:muvam_rider/features/analytics/data/models/overview_response_model.dart';

class EarningsProvider extends ChangeNotifier {
  final EarningsService _earningsService = EarningsService();

  EarningsSummary? _earningsSummary;
  OverviewResponse? _overviewResponse;

  bool _isLoading = false;
  bool _isLoadingOverview = false;
  String? _errorMessage;
  EarningsSummary? get earningsSummary => _earningsSummary;
  OverviewResponse? get overviewResponse => _overviewResponse;
  WeeklyOverviewData? get weeklyOverview => _overviewResponse?.overview;
  RecentRides? get recentRides => _overviewResponse?.recentRides;

  bool get isLoading => _isLoading;
  bool get isLoadingOverview => _isLoadingOverview;
  String? get errorMessage => _errorMessage;

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
          AppLogger.log('Earnings summary parsed successfully');
        } else {
          _errorMessage = 'No summary data available';
          _earningsSummary = null;
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch earnings summary';
        _earningsSummary = null;
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

  Future<void> fetchEarningsOverview(String period) async {
    _isLoadingOverview = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching earnings overview for period: $period');

      final result = await _earningsService.getEarningsOverview(period: period);

      if (result['success'] == true && result['data'] != null) {
        _overviewResponse = OverviewResponse.fromJson(result['data']);
        _errorMessage = null;
        AppLogger.log(
          'Overview fetched: ${_overviewResponse?.overview.dailyBreakdown.length ?? 0} days, ${_overviewResponse?.recentRides.count ?? 0} rides',
        );
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch overview';
        _overviewResponse = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching overview: $e';
      AppLogger.log('Exception in fetchEarningsOverview: $e');
      _overviewResponse = null;
    } finally {
      _isLoadingOverview = false;
      notifyListeners();
    }
  }

  String formatPrice(double price) {
    if (price >= 1000) {
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

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      AppLogger.log('Date format error: $e');
      return '';
    }
  }

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

  void clearData() {
    _earningsSummary = null;
    _overviewResponse = null;
    _errorMessage = null;
    notifyListeners();
  }
}
