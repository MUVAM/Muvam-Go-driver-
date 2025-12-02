import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class KycProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> uploadDocuments({
    required File driverLicense,
    required File vehicleRegistration,
    required File insurance,
    required String token,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final result = await ApiService.uploadVerificationDocuments(
        driverLicense: driverLicense,
        vehicleRegistration: vehicleRegistration,
        insurance: insurance,
        token: token,
      );
      
      if (result['success'] == true) {
        _isVerified = true;
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to upload documents');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}