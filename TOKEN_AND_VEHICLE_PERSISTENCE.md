# Token and Vehicle Submission Persistence Implementation

## Overview
This implementation ensures that user authentication tokens and vehicle submission status are persisted locally, allowing the app to automatically navigate users to the appropriate screen on app launch.

## Changes Made

### 1. Auth Service (`lib/core/services/auth_service.dart`)
Added methods to persist and retrieve vehicle submission status:

```dart
Future<void> saveVehicleSubmittedStatus(bool vehicleSubmitted) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('vehicle_submitted', vehicleSubmitted);
}

Future<bool> getVehicleSubmittedStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('vehicle_submitted') ?? false;
}
```

### 2. Auth Provider (`lib/features/auth/data/provider/auth_provider.dart`)
Updated the `verifyOtp` method to automatically save the `vehicle_submitted` status from the API response:

```dart
Future<bool> verifyOtp(String code, String phone) async {
  _setLoading(true);
  _setError(null);

  try {
    _verifyOtpResponse = await _authService.verifyOtp(code, phone);
    
    // Save vehicle_submitted status
    if (_verifyOtpResponse != null) {
      final vehicleSubmitted = _verifyOtpResponse?['vehicle_submitted'] ?? false;
      await _authService.saveVehicleSubmittedStatus(vehicleSubmitted);
    }
    
    _setLoading(false);
    return true;
  } catch (e) {
    // ... error handling
  }
}
```

### 3. Splash Screen (`lib/shared/presentation/screens/splash_screen.dart`)
Updated the navigation logic to check for both token and vehicle submission status:

```dart
Future<void> _checkAuthAndNavigate() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Check if user has a valid token
  final token = prefs.getString('auth_token');
  final vehicleSubmitted = prefs.getBool('vehicle_submitted') ?? false;
  
  // Check if this is the first time the user is opening the app
  final isFirstTime = await _isFirstTimeUser();

  if (isFirstTime) {
    // First-time user: show rider selection screen
    await _markAppAsOpened();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RiderSignupSelectionScreen(),
      ),
    );
  } else if (token != null && token.isNotEmpty && vehicleSubmitted) {
    // User has token and vehicle submitted: go to home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(),
      ),
    );
  } else {
    // No token or vehicle not submitted: show phone number login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }
}
```

## How It Works

### On OTP Verification
1. When a user verifies their OTP, the API returns a response containing:
   - `token` object with `access_token`, `refresh_token`, and `expires_in`
   - `vehicle_submitted` boolean field
   - User information

2. The `auth_service.dart` automatically saves:
   - Access token to `auth_token` key
   - Refresh token to `refresh_token` key
   - Token expiry time to `token_expiry` key

3. The `auth_provider.dart` additionally saves:
   - Vehicle submission status to `vehicle_submitted` key

### On App Launch
The splash screen checks three conditions:

1. **First-time user**: Shows the rider signup selection screen
2. **Authenticated user with vehicle submitted**: Navigates directly to the home screen (MainNavigationScreen)
3. **No token OR vehicle not submitted**: Shows the phone number login screen (OnboardingScreen)

## Navigation Flow

```
App Launch
    ↓
Splash Screen
    ↓
Check Conditions
    ↓
    ├─→ First Time? → Rider Signup Selection Screen
    ├─→ Token + Vehicle Submitted? → Home Screen (MainNavigationScreen)
    └─→ Otherwise → Phone Number Login Screen (OnboardingScreen)
```

## Stored Data Keys

The following keys are used in SharedPreferences:

- `auth_token`: Access token for API authentication
- `refresh_token`: Refresh token for token renewal
- `token_expiry`: Token expiration timestamp
- `vehicle_submitted`: Boolean indicating if vehicle documents are submitted
- `has_opened_app`: Boolean indicating if the app has been opened before
- `last_login_time`: Timestamp of last login
- `user_id`: User's ID
- `first_name`: User's first name
- `last_name`: User's last name
- `email`: User's email
- `profile_photo`: User's profile photo URL

## Benefits

1. **Seamless User Experience**: Users don't need to log in every time they open the app
2. **Smart Navigation**: Users are automatically directed to the appropriate screen based on their status
3. **Persistent State**: Vehicle submission status is maintained across app sessions
4. **Security**: Token expiry is tracked to ensure secure authentication

## Testing

To test the implementation:

1. **New User Flow**:
   - Install the app for the first time
   - Should see the rider signup selection screen

2. **Returning User with Vehicle Submitted**:
   - Log in and complete vehicle submission
   - Close and reopen the app
   - Should navigate directly to the home screen

3. **Returning User without Vehicle Submitted**:
   - Log in but don't submit vehicle documents
   - Close and reopen the app
   - Should navigate to the phone number login screen

4. **User without Token**:
   - Clear app data or uninstall/reinstall
   - Should navigate to the phone number login screen
