# First-Time User Flow Implementation

## Overview
Implemented a user flow that differentiates between first-time users and returning users when they open the app.

## User Flow Logic

### 1. **First-Time User** (Never opened the app before)
- **Screen Shown**: `RiderSignupSelectionScreen`
- **Purpose**: Allow new users to select their service type (Taxi Driver or Delivery Rider)
- **Trigger**: When `has_opened_app` preference is `null` or `true` AND no valid auth token exists

### 2. **Returning User Without Token** (Logged out or token expired)
- **Screen Shown**: `OnboardingScreen` (Phone number input)
- **Purpose**: Allow returning users to quickly log back in without going through service selection
- **Trigger**: When `has_opened_app` preference is `false` AND no valid auth token exists

### 3. **Returning User With Valid Token**
- **Screen Shown**: `HomeScreen` (or `BiometricLockScreen` if biometrics enabled)
- **Purpose**: Direct access to the app for authenticated users
- **Trigger**: When a valid, non-expired auth token exists

## Implementation Details

### Changes Made to `splash_screen.dart`

#### 1. Added New Imports
```dart
import 'package:muvam_rider/shared/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

#### 2. Updated `_checkAuthAndNavigate()` Method
- Added logic to check if user is opening the app for the first time
- Routes to appropriate screen based on user status:
  - First-time → `RiderSignupSelectionScreen`
  - Returning without token → `OnboardingScreen`
  - Returning with expired session → `OnboardingScreen`
  - Authenticated → `HomeScreen` or `BiometricLockScreen`

#### 3. Added Helper Methods

**`_isFirstTimeUser()`**
```dart
Future<bool> _isFirstTimeUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_opened_app') ?? true;
}
```
- Checks SharedPreferences for `has_opened_app` flag
- Returns `true` if flag doesn't exist or is `true`
- Returns `false` if flag is `false`

**`_markAppAsOpened()`**
```dart
Future<void> _markAppAsOpened() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_opened_app', false);
}
```
- Sets the `has_opened_app` flag to `false` after first launch
- Called only when showing `RiderSignupSelectionScreen` to first-time users

## User Experience

### First Launch
1. User opens app for the first time
2. Splash screen displays
3. App checks: No token + `has_opened_app` is `true`
4. **Result**: Shows `RiderSignupSelectionScreen`
5. Flag `has_opened_app` is set to `false`

### Subsequent Launches (Logged Out)
1. User opens app again (after logout or token expiry)
2. Splash screen displays
3. App checks: No token + `has_opened_app` is `false`
4. **Result**: Shows `OnboardingScreen` (phone number input)

### Subsequent Launches (Logged In)
1. User opens app with valid session
2. Splash screen displays
3. App checks: Valid token exists
4. **Result**: Shows `HomeScreen` (or biometric lock if enabled)

## Benefits

1. **Better UX for Returning Users**: No need to go through service selection every time they log in
2. **Streamlined Login**: Returning users can quickly enter their phone number and get back into the app
3. **Proper Onboarding**: First-time users still get the full onboarding experience with service selection
4. **Persistent State**: Uses SharedPreferences to remember if the user has used the app before

## Testing Scenarios

### To Test First-Time Flow
1. Uninstall and reinstall the app
2. Launch the app
3. Should see `RiderSignupSelectionScreen`

### To Test Returning User Flow
1. Complete first-time setup
2. Log out or clear token
3. Relaunch the app
4. Should see `OnboardingScreen` (phone number input)

### To Reset First-Time Flag (For Testing)
Clear app data or use this code:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('has_opened_app');
```

## Notes
- The `has_opened_app` flag persists even after logout
- Only uninstalling the app or clearing app data will reset this flag
- This ensures returning users always get the streamlined login experience
