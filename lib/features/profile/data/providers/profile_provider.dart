import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/profile_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
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

  // Convenient getters
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
    AppLogger.log('📱 ProfileProvider: Fetching user profile...');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.getUserProfile();

      if (profile != null) {
        _profileResponse = profile;
        _isLoading = false;
        notifyListeners();

        AppLogger.log('ProfileProvider: Profile loaded successfully');
        AppLogger.log('   User: ${profile.user.fullName}');

        return true;
      } else {
        _errorMessage = 'Failed to load profile';
        _isLoading = false;
        notifyListeners();

        AppLogger.log('ProfileProvider: Failed to load profile');
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      AppLogger.log('ProfileProvider: Error - $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String dateOfBirth,
  }) async {
    AppLogger.log('UserProfileProvider: Updating user profile');

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

        AppLogger.log('UserProfileProvider: Profile updated successfully');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update profile';
        AppLogger.log('UserProfileProvider: Update failed - $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      AppLogger.log('UserProfileProvider: Error updating profile - $e');
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

    AppLogger.log('🗑️ ProfileProvider: Profile cleared');
  }

  // Method to refresh profile data
  Future<void> refreshProfile() async {
    AppLogger.log('🔄 ProfileProvider: Refreshing profile...');
    await fetchUserProfile();
  }
}
