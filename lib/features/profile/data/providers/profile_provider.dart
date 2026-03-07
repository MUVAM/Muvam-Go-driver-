import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/profile_service.dart';
import 'package:muvam_rider/features/profile/data/models/profile_models.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileResponse? _profileResponse;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  ProfileResponse? get profileResponse => _profileResponse;
  UserProfile? get userProfile => _profileResponse?.user;
  Vehicle? get defaultVehicle => _profileResponse?.defaultVehicle;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  String get userName => userProfile?.fullName ?? 'User';
  String get userShortName => userProfile?.shortName ?? 'User';
  String get userEmail => userProfile?.email ?? '';
  String get userPhone => userProfile?.phone ?? '';
  String get userCity => userProfile?.city ?? '';
  String get userProfilePhoto => userProfile?.profilePhoto ?? '';
  String get userDateOfBirth => userProfile?.dateOfBirth ?? '';
  double get userRating => userProfile?.averageRating ?? 0.0;
  int get ratingCount => userProfile?.ratingCount ?? 0;
  bool get isProfileComplete => userProfile?.profileComplete ?? false;

  Future<bool> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.getUserProfile();

      if (profile != null) {
        _profileResponse = profile;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to load profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _profileService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
      );

      _isUpdating = false;

      if (result['success'] == true) {
        await fetchUserProfile();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, String?>> getCachedUserData() async {
    return await _profileService.getCachedUserData();
  }

  Future<void> clearProfile() async {
    _profileResponse = null;
    _errorMessage = null;
    await _profileService.clearCachedUserData();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }
}
