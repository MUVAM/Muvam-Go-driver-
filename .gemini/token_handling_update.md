# Token Handling Update Summary

## Overview
Updated the authentication service to handle the new token response structure from the verify OTP endpoint.

## Changes Made

### 1. New Token Structure
The verify OTP endpoint now returns a nested token object instead of a simple string:

```json
{
  "isNew": false,
  "message": "Phone number verified successfully",
  "token": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 3600
  },
  "user": { ... }
}
```

### 2. Updated Files

#### `lib/core/services/auth_service.dart`

**Added Constants:**
- `_refreshTokenKey`: Storage key for refresh token
- `_tokenExpiryKey`: Storage key for token expiry timestamp

**Updated Methods:**

1. **`verifyOtp()`** - Now handles both old and new token structures:
   - Detects if token is an object or string
   - Extracts `access_token`, `refresh_token`, and `expires_in`
   - Saves all token data appropriately

2. **`_saveRefreshToken()`** - New method to save refresh token

3. **`_saveTokenExpiry()`** - New method to save token expiry time
   - Calculates absolute expiry timestamp (current time + expires_in seconds)

4. **`getRefreshToken()`** - New public method to retrieve refresh token

5. **`clearToken()`** - Updated to also clear refresh token and expiry data

## Token Storage Details

### Access Token
- **Key:** `auth_token`
- **Usage:** Used for API authentication in `Authorization: Bearer {token}` headers
- **Retrieved via:** `getToken()`

### Refresh Token
- **Key:** `refresh_token`
- **Usage:** Can be used to obtain a new access token when it expires
- **Retrieved via:** `getRefreshToken()`

### Token Expiry
- **Key:** `token_expiry`
- **Format:** Milliseconds since epoch (absolute timestamp)
- **Calculation:** Current time + (expires_in * 1000)

## Backward Compatibility

The implementation maintains backward compatibility with the old token structure:
- If `token` is a string, it saves it directly as the access token
- If `token` is an object, it extracts and saves all token components

## Next Steps (Optional Enhancements)

### 1. Token Refresh Logic
You may want to implement automatic token refresh:

```dart
Future<bool> isTokenExpired() async {
  final prefs = await SharedPreferences.getInstance();
  final expiryString = prefs.getString(_tokenExpiryKey);
  
  if (expiryString == null) return true;
  
  final expiryTime = int.tryParse(expiryString) ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  // Consider token expired if less than 5 minutes remaining
  return now >= (expiryTime - 300000);
}

Future<String?> refreshAccessToken() async {
  final refreshToken = await getRefreshToken();
  if (refreshToken == null) return null;
  
  try {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final newAccessToken = result['access_token'];
      final newExpiresIn = result['expires_in'];
      
      if (newAccessToken != null) {
        await _saveToken(newAccessToken);
        if (newExpiresIn != null) {
          await _saveTokenExpiry(newExpiresIn);
        }
        return newAccessToken;
      }
    }
  } catch (e) {
    // Handle error
  }
  
  return null;
}
```

### 2. Automatic Token Refresh in API Calls
Consider adding an interceptor to automatically refresh tokens before API calls:

```dart
Future<String?> getValidToken() async {
  if (await isTokenExpired()) {
    return await refreshAccessToken();
  }
  return await getToken();
}
```

### 3. Update API Service
Update all API calls to use the new token retrieval method:

```dart
// Before
final token = await authService.getToken();

// After (with auto-refresh)
final token = await authService.getValidToken();
```

## Testing Checklist

- [x] Token extraction from new response structure
- [x] Access token storage
- [x] Refresh token storage
- [x] Token expiry calculation and storage
- [x] Token retrieval methods
- [x] Token cleanup on logout
- [ ] Test actual OTP verification flow
- [ ] Verify token is used correctly in API calls
- [ ] Test token refresh logic (if implemented)

## Current Status

✅ **Complete** - The authentication service now properly handles the new token structure from the verify OTP endpoint. All tokens are stored and can be retrieved as needed.
