import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/services/request_service.dart';
import 'package:muvam_rider/features/activities/data/models/ride_data.dart';

class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();

  List<RideData> _prebookedRides = [];
  List<RideData> _activeRides = [];
  List<RideData> _historyRides = [];
  RideData? _selectedRide;

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  List<RideData> get prebookedRides => _prebookedRides;
  List<RideData> get activeRides => _activeRides;
  List<RideData> get historyRides => _historyRides;
  RideData? get selectedRide => _selectedRide;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  bool get hasData =>
      _prebookedRides.isNotEmpty ||
      _activeRides.isNotEmpty ||
      _historyRides.isNotEmpty;

  RequestProvider() {
    fetchRides();
    startPolling();
  }

  Future<void> fetchRides({bool isBackground = false}) async {
    // Only show loading spinner on first load when there's no data
    if (!isBackground && !hasData) {
      _isLoading = true;
    } else if (isBackground) {
      _isRefreshing = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      //Fetching rides (background: $isBackground)');

      // Store previous counts to detect changes
      final previousPrebookedCount = _prebookedRides.length;
      final previousActiveCount = _activeRides.length;
      final previousHistoryCount = _historyRides.length;

      // Fetch all rides in parallel for faster response
      final results = await Future.wait([
        _requestService.getPrebookedRides(),
        _requestService.getActiveRides(),
        _requestService.getHistoryRides(),
      ]);

      final prebookedResult = results[0];
      final activeResult = results[1];
      final historyResult = results[2];

      // Process prebooked rides
      if (prebookedResult['success'] == true &&
          prebookedResult['data'] != null) {
        _prebookedRides = _parseRides(prebookedResult['data']);
        //Prebooked rides: ${_prebookedRides.length}');

        if (isBackground && _prebookedRides.length > previousPrebookedCount) {
          //📅 New prebooked ride(s) detected!');
        }
      } else {
        _prebookedRides = [];
        if (!hasData && prebookedResult['success'] == false) {
          _errorMessage = prebookedResult['message'] ?? 'Failed to fetch rides';
        }
      }

      // Process active rides
      if (activeResult['success'] == true && activeResult['data'] != null) {
        _activeRides = _parseRides(activeResult['data']);
        //Active rides: ${_activeRides.length}');

        if (isBackground && _activeRides.length > previousActiveCount) {
          //🚗 New active ride(s) detected!');
        }
      } else {
        _activeRides = [];
        if (!hasData &&
            activeResult['success'] == false &&
            _errorMessage == null) {
          _errorMessage = activeResult['message'] ?? 'Failed to fetch rides';
        }
      }

      // Process history rides
      if (historyResult['success'] == true && historyResult['data'] != null) {
        _historyRides = _parseRides(historyResult['data']);
        //History rides: ${_historyRides.length}');

        if (isBackground && _historyRides.length > previousHistoryCount) {
          //📜 New history ride(s) detected!');
        }
      } else {
        _historyRides = [];
        if (!hasData &&
            historyResult['success'] == false &&
            _errorMessage == null) {
          _errorMessage = historyResult['message'] ?? 'Failed to fetch rides';
        }
      }

      //All rides fetched successfully');
    } catch (e) {
      _errorMessage = 'Error fetching rides: $e';
      //Exception: $e');
      if (!hasData) {
        _prebookedRides = [];
        _activeRides = [];
        _historyRides = [];
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideDetails(int rideId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //Fetching ride details: $rideId');

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
      //Exception in fetchRideDetails: $e');
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
              //Failed to parse ride: $e');
              return null;
            }
          })
          .whereType<RideData>()
          .toList();
    } catch (e) {
      //Error parsing rides: $e');
      return [];
    }
  }

  void startPolling() {
    //Starting automatic polling every 10 seconds');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchRides(isBackground: true),
    );
  }

  void stopPolling() {
    //Stopping automatic polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void pausePolling() {
    //Pausing polling');
    _pollingTimer?.cancel();
  }

  void resumePolling() {
    //Resuming polling');
    startPolling();
    fetchRides(isBackground: true);
  }

  void startAutoRefresh() {
    startPolling();
  }

  void stopAutoRefresh() {
    stopPolling();
  }

  String formatPrice(double price) {
    return '₦${price.toStringAsFixed(2)}';
  }

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      //Date format error: $e');
      return dateTimeStr;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
