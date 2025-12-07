import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProvider extends ChangeNotifier {
  bool _isOnline = false;
  double _currentDuration = 0;
  double _onlineHours = 0;
  Map<String, dynamic>? _session;
  bool _isLoading = false;

  bool get isOnline => _isOnline;
  double get currentDuration => _currentDuration;
  double get onlineHours => _onlineHours;
  Map<String, dynamic>? get session => _session;
  bool get isLoading => _isLoading;

  Future<void> initializeDriverStatus() async {
    await getDriverStatus();
  }

  Future<void> getDriverStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final result = await ApiService.getDriverStatus(token);
        if (result['success'] == true) {
          final data = result['data'];
          _isOnline = data['is_online'] ?? false;
          _currentDuration = (data['current_duration'] ?? 0).toDouble();
          _onlineHours = (data['online_hours'] ?? 0).toDouble();
          _session = data['session'];
        }
      }
    } catch (e) {
      print('Error getting driver status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleDriverStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final result = _isOnline 
            ? await ApiService.setDriverOfflineStatus(token)
            : await ApiService.setDriverOnlineStatus(token);
            
        if (result['success'] == true) {
          await getDriverStatus(); // Refresh status
          return true;
        }
      }
    } catch (e) {
      print('Error toggling driver status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
  }

  Future<bool> setOnline() async {
    if (_isOnline) return true;
    
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final result = await ApiService.setDriverOnlineStatus(token);
        if (result['success'] == true) {
          await getDriverStatus();
          return true;
        }
      }
    } catch (e) {
      print('Error setting driver online: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
  }

  Future<bool> setOffline() async {
    if (!_isOnline) return true;
    
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final result = await ApiService.setDriverOfflineStatus(token);
        if (result['success'] == true) {
          await getDriverStatus();
          return true;
        }
      }
    } catch (e) {
      print('Error setting driver offline: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
  }
}