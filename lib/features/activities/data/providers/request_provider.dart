import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/services/request_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/activities/data/models/ride_data.dart';

class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();

  List<RideData> _prebookedRides = [];
  List<RideData> _activeRides = [];
  List<RideData> _historyRides = [];
  RideData? _selectedRide;

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<RideData> get prebookedRides => _prebookedRides;
  List<RideData> get activeRides => _activeRides;
  List<RideData> get historyRides => _historyRides;
  RideData? get selectedRide => _selectedRide;

  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  RequestProvider() {
    fetchRides();
  }

  Future<void> fetchRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching rides');

      final prebookedResult = await _requestService.getPrebookedRides();
      if (prebookedResult['success'] == true &&
          prebookedResult['data'] != null) {
        _prebookedRides = _parseRides(prebookedResult['data']);
      } else {
        _prebookedRides = [];
        if (prebookedResult['success'] == false) {
          _errorMessage = prebookedResult['message'] ?? 'Failed to fetch rides';
        }
      }

      final activeResult = await _requestService.getActiveRides();
      if (activeResult['success'] == true && activeResult['data'] != null) {
        _activeRides = _parseRides(activeResult['data']);
      } else {
        _activeRides = [];
        if (activeResult['success'] == false && _errorMessage == null) {
          _errorMessage = activeResult['message'] ?? 'Failed to fetch rides';
        }
      }

      final historyResult = await _requestService.getHistoryRides();
      if (historyResult['success'] == true && historyResult['data'] != null) {
        _historyRides = _parseRides(historyResult['data']);
      } else {
        _historyRides = [];
        if (historyResult['success'] == false && _errorMessage == null) {
          _errorMessage = historyResult['message'] ?? 'Failed to fetch rides';
        }
      }
    } catch (e) {
      _errorMessage = 'Error fetching rides: $e';
      AppLogger.log('Exception: $e');
      _prebookedRides = [];
      _activeRides = [];
      _historyRides = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideDetails(int rideId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching ride details: $rideId');

      final result = await _requestService.getRideDetails(rideId);

      if (result['success'] == true && result['data'] != null) {
        _selectedRide = RideData.fromJson(result['data']);
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch ride details';
        _selectedRide = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching ride details: $e';
      AppLogger.log('Exception in fetchRideDetails: $e');
      _selectedRide = null;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  void clearSelectedRide() {
    _selectedRide = null;
    notifyListeners();
  }

  List<RideData> _parseRides(dynamic data) {
    try {
      List<dynamic> ridesJson = [];

      if (data is Map<String, dynamic> && data['rides'] is List) {
        ridesJson = data['rides'];
      } else if (data is List) {
        ridesJson = data;
      }

      return ridesJson
          .map((e) {
            try {
              return RideData.fromJson(e);
            } catch (e) {
              AppLogger.log('Failed to parse ride: $e');
              return null;
            }
          })
          .whereType<RideData>()
          .toList();
    } catch (e) {
      AppLogger.log('Error parsing rides: $e');
      return [];
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchRides(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  String formatPrice(double price) {
    return '₦${price.toStringAsFixed(2)}';
  }

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      AppLogger.log('Date format error: $e');
      return dateTimeStr;
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
