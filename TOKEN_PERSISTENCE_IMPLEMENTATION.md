# Token Persistence Implementation

## Overview
The driver app now persists authentication tokens with a 1-hour expiry time. Drivers will not need to request OTP every time they open the app, as long as their token is still valid.

## Key Changes

### 1. AuthService (`lib/core/services/auth_service.dart`)
- **Token Expiry**: Tokens now expire after 1 hour from login
- **Auto-expiry Check**: When getting a token, the service automatically checks if it has expired
- **Automatic Cleanup**: Expired tokens are automatically cleared

#### Key Methods:
- `getToken()`: Returns token only if it's still valid (not expired)
- `isTokenExpired()`: Checks if the current token has expired
- `_saveToken()`: Saves token with 1-hour expiry timestamp

### 2. SplashScreen (`lib/shared/presentation/screens/splash_screen.dart`)
- **Auto-login**: Checks for valid token on app startup
- **Smart Navigation**: 
  - If valid token exists → Navigate to MainNavigationScreen
  - If no valid token → Navigate to login/onboarding screen

### 3. AuthProvider (`lib/features/auth/data/provider/auth_provider.dart`)
- **New Method**: `isAuthenticated()` - Easy way to check if user is authenticated

## How It Works

1. **After OTP Verification**:
   - Token is saved to SharedPreferences
   - Expiry timestamp is calculated (current time + 1 hour)
   - Both token and expiry time are stored

2. **On App Launch**:
   - SplashScreen checks for existing token
   - If token exists and hasn't expired → Auto-login
   - If token expired or doesn't exist → Show login screen

3. **Token Validation**:
   - Every time `getToken()` is called, expiry is checked
   - Expired tokens are automatically cleared
   - Returns `null` if token is expired

## Token Expiry Duration
- **Current Setting**: 1 hour
- **Location**: `AuthService._tokenValidityHours` constant
- **To Change**: Modify the `_tokenValidityHours` value in `auth_service.dart`

## Storage Keys
- `auth_token`: The authentication token
- `token_expiry`: Timestamp when token expires (milliseconds since epoch)
- `last_login_time`: Last login timestamp for reference

## Testing
1. Login with OTP
2. Close the app
3. Reopen within 1 hour → Should auto-login
4. Wait 1 hour and reopen → Should show login screen

## Security Notes
- Tokens are stored in SharedPreferences (encrypted on device)
- Expired tokens are automatically cleared
- No sensitive data is logged
