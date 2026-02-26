import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = UrlConstants.baseUrl;

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      //Sending OTP to: $phoneNumber');
      //URL: $baseUrl${UrlConstants.sendOtp}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.sendOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Phone': phoneNumber}),
      );

      //Response status: ${response.statusCode}');
      //Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      //Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.resendOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Phone': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      //=== VERIFY OTP DEBUG ===');
      //Phone: $phoneNumber');
      //OTP: $otp');
      //URL: $baseUrl${UrlConstants.verifyOtp}');

      final requestBody = {'Phone': phoneNumber, 'Code': otp};
      //Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.verifyOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        //✅ SUCCESS: OTP verified');
        //Full response: $data');

        final prefs = await SharedPreferences.getInstance();

        // Save token data (access_token, refresh_token, expiry)
        if (data['token'] != null) {
          final tokenData = data['token'];
          if (tokenData is Map<String, dynamic>) {
            final accessToken = tokenData['access_token'];
            final refreshToken = tokenData['refresh_token'];
            final expiresIn = tokenData['expires_in'];

            if (accessToken != null) {
              await prefs.setString('auth_token', accessToken);
              //✅ Access token saved');
            }
            if (refreshToken != null) {
              await prefs.setString('refresh_token', refreshToken);
              //✅ Refresh token saved');
            }
            if (expiresIn != null) {
              final expiryTime =
                  DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
              await prefs.setInt('token_expiry', expiryTime.toInt());
              //✅ Token expiry saved');
            }
          }
        }

        // Save vehicle_submitted status directly from response
        final vehicleSubmitted = data['vehicle_submitted'] ?? false;
        //📊 Backend vehicle_submitted value: $vehicleSubmitted');
        await prefs.setBool('vehicle_submitted', vehicleSubmitted);
        //✅ vehicle_submitted saved: $vehicleSubmitted');

        // Immediately verify it was saved
        final savedValue = prefs.getBool('vehicle_submitted');
        //🔍 Immediate verification read: $savedValue');

        if (savedValue != vehicleSubmitted) {
          AppLogger.log(
            '❌ WARNING: Saved value does not match! Expected: $vehicleSubmitted, Got: $savedValue',
          );
        }

        // Save user data
        if (data['user'] != null) {
          final user = data['user'];

          if (user['ID'] != null) {
            await prefs.setString('user_id', user['ID'].toString());
          }
          if (user['first_name'] != null) {
            await prefs.setString('first_name', user['first_name'].toString());
          }
          if (user['last_name'] != null) {
            await prefs.setString('last_name', user['last_name'].toString());
          }
          if (user['Email'] != null) {
            await prefs.setString('email', user['Email'].toString());
          }
          if (user['phone'] != null) {
            await prefs.setString('phone', user['phone'].toString());
          }
          if (user['profile_photo'] != null) {
            await prefs.setString(
              'profile_photo',
              user['profile_photo'].toString(),
            );
          }
          if (user['Role'] != null) {
            await prefs.setString('user_role', user['Role'].toString());
          }
          //✅ User data saved successfully');
        }

        return {'success': true, 'data': data};
      } else {
        //❌ ERROR: OTP verification failed');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? error['error'] ?? 'Invalid OTP',
        };
      }
    } catch (e, stackTrace) {
      //❌ VERIFY OTP ERROR: $e');
      //Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END VERIFY OTP DEBUG ===\n');
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String lga,
    required String homeAddress,
    required String city,
    required String location,
    String? referralCode,
    String serviceType = 'taxi',
  }) async {
    try {
      //=== REGISTER DRIVER DEBUG ===');
      final requestBody = {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'email': email,
        'phone': phoneNumber,
        'date_of_birth': dateOfBirth,
        'role': 'driver',
        'city': city,
        'lga': lga,
        'location': location,
        'home_address': homeAddress,
        'referral_code': referralCode,
        'service_type': serviceType,
      };
      //Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.registerUser}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Save token to SharedPreferences
        if (data['token'] != null) {
          final tokenData = data['token'];
          final prefs = await SharedPreferences.getInstance();

          if (tokenData is Map<String, dynamic>) {
            // Save access token
            final accessToken = tokenData['access_token'];
            if (accessToken != null) {
              await prefs.setString('auth_token', accessToken);
              //Access token saved successfully');
            }

            // Save refresh token
            final refreshToken = tokenData['refresh_token'];
            if (refreshToken != null) {
              await prefs.setString('refresh_token', refreshToken);
              //Refresh token saved successfully');
            }

            // Save token expiry
            final expiresIn = tokenData['expires_in'];
            if (expiresIn != null) {
              final expiryTime =
                  DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
              await prefs.setString('token_expiry', expiryTime.toString());
              //Token expiry saved successfully');
            }

            // Save last login time
            await prefs.setString(
              'last_login_time',
              DateTime.now().millisecondsSinceEpoch.toString(),
            );
          }
        }

        // Save user data
        if (data['user'] != null) {
          final user = data['user'];
          final prefs = await SharedPreferences.getInstance();

          if (user['ID'] != null) {
            await prefs.setString('user_id', user['ID'].toString());
          }
          if (user['first_name'] != null) {
            await prefs.setString('first_name', user['first_name'].toString());
          }
          if (user['last_name'] != null) {
            await prefs.setString('last_name', user['last_name'].toString());
          }
          if (user['Email'] != null) {
            await prefs.setString('email', user['Email'].toString());
          }
          if (user['profile_photo'] != null) {
            await prefs.setString(
              'profile_photo',
              user['profile_photo'].toString(),
            );
          }
          //User data saved successfully');
        }
        return {'success': true, 'data': data};
      } else {
        final errorBody = jsonDecode(response.body);
        String errorMessage =
            errorBody['error'] ?? errorBody['message'] ?? 'Registration failed';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      //REGISTER ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END REGISTER DRIVER DEBUG ===\n');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get nearby rides
  static Future<Map<String, dynamic>> getNearbyRides(String token) async {
    try {
      //=== GET NEARBY RIDES DEBUG ===');
      //URL: $baseUrl/rides/nearby');
      //Token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/rides/nearby'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to get rides',
        };
      }
    } catch (e) {
      //GET NEARBY RIDES ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END GET NEARBY RIDES DEBUG ===\n');
    }
  }

  // Accept ride
  static Future<Map<String, dynamic>> acceptRide(
    String token,
    int rideId,
  ) async {
    try {
      //=== ACCEPT RIDE DEBUG ===');
      //URL: $baseUrl/rides/accept/$rideId');
      //Token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/accept/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to accept ride',
        };
      }
    } catch (e) {
      //ACCEPT RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END ACCEPT RIDE DEBUG ===\n');
    }
  }

  // Reject ride
  static Future<Map<String, dynamic>> rejectRide(
    String token,
    int rideId,
  ) async {
    try {
      //=== REJECT RIDE DEBUG ===');
      //URL: $baseUrl/rides/reject/$rideId');
      //Token: $token');
      //Ride ID: $rideId');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/reject/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to reject ride',
        };
      }
    } catch (e) {
      //REJECT RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END REJECT RIDE DEBUG ===\n');
    }
  }

  // Decline ride
  static Future<Map<String, dynamic>> declineRide(
    String token,
    int rideId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.rideCancel}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to decline ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Mark ride as arrived
  static Future<Map<String, dynamic>> arriveRide(
    String token,
    int rideId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.rideArrive}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to mark as arrived',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Cancel ride with reason
  static Future<Map<String, dynamic>> cancelRideWithReason(
    String token,
    int rideId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.rideCancel}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ride_id': rideId, 'reason': reason}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to cancel ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Driver online status
  static Future<Map<String, dynamic>> setDriverOnlineStatus(
    String token,
  ) async {
    try {
      //=== DRIVER ONLINE STATUS DEBUG ===');
      //URL: $baseUrl/driver/online');
      //Token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/driver/online'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      //DRIVER STATUS ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END DRIVER ONLINE STATUS DEBUG ===\n');
    }
  }

  // Driver offline status
  static Future<Map<String, dynamic>> setDriverOfflineStatus(
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.driverOffline}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get driver status
  static Future<Map<String, dynamic>> getDriverStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${UrlConstants.driverStatus}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to get status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Upload verification documents (Driver License only)
  static Future<Map<String, dynamic>> uploadVerificationDocuments({
    required File driverLicenseFile,
    required String driverLicenseNumber,
    required String token,
  }) async {
    try {
      AppLogger.log(
        '=== UPLOAD VERIFICATION DOCUMENTS (DRIVER LICENSE) DEBUG ===',
      );
      //URL: $baseUrl/users/verification');
      //Token: ${token.substring(0, 20)}...');
      //Driver License Number: $driverLicenseNumber');
      //Driver License File Path: ${driverLicenseFile.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/verification'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add driver license number as a field
      request.fields['driver_license'] = driverLicenseNumber;

      // Add driver license file
      request.files.add(
        await http.MultipartFile.fromPath(
          'driver_license_file',
          driverLicenseFile.path,
        ),
      );

      //Request fields: ${request.fields}');
      //Request headers: ${request.headers}');
      //Files added to request: ${request.files.length}');
      //Sending verification request...');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      //Response Status: ${response.statusCode}');
      //Response Body verification: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        //✅ Driver license verification successful');
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 413) {
        //❌ 413 Request Entity Too Large');
        return {
          'success': false,
          'message':
              'Driver license file is too large. Please select a smaller image (max 2MB).',
        };
      } else {
        AppLogger.log(
          '❌ Verification upload failed with status: ${response.statusCode}',
        );
        try {
          final error = jsonDecode(responseBody);
          return {
            'success': false,
            'message': error['message'] ?? error['error'] ?? 'Upload failed',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Upload failed. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e, stackTrace) {
      //❌ UPLOAD VERIFICATION ERROR: $e');
      //Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END UPLOAD VERIFICATION DOCUMENTS DEBUG ===\n');
    }
  }

  // Register vehicle
  // Register vehicle
  static Future<Map<String, dynamic>> registerVehicle({
    required String make,
    required String modelType,
    required String seats,
    required String year,
    required String licenseNumber,
    required String color,
    required String licensePlate,
    required File registrationDoc,
    required File insuranceDoc,
    required List<File> vehiclePhotos,
    required String token,
    required bool ac,
  }) async {
    try {
      //=== REGISTER VEHICLE API DEBUG ===');
      //URL: $baseUrl${UrlConstants.registerVehicle}');
      //Token: ${token.substring(0, 20)}...');
      //Make: $make');
      //Model Type: $modelType');
      //Seats: $seats');
      //Year: $year');
      //License Number: $licenseNumber');
      //Color: $color');
      //License Plate: $licensePlate');
      //AC: $ac');
      //Vehicle Photos: ${vehiclePhotos.length}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${UrlConstants.registerVehicle}'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['make'] = make;
      request.fields['model_type'] = modelType;
      request.fields['seats'] = seats;
      request.fields['year'] = year;
      request.fields['license_number'] = licenseNumber;
      request.fields['color'] = color;
      request.fields['license_plate'] = licensePlate;
      request.fields['ac'] = ac.toString();

      //Request fields: ${request.fields}');
      //Request headers: ${request.headers}');

      request.files.add(
        await http.MultipartFile.fromPath(
          'registration_doc',
          registrationDoc.path,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath('insurance_doc', insuranceDoc.path),
      );
      for (var photo in vehiclePhotos) {
        request.files.add(
          await http.MultipartFile.fromPath('photos', photo.path),
        );
      }

      //Files added to request: ${request.files.length}');
      //Sending request...');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      //Response Status: ${response.statusCode}');
      //Response Headers: ${response.headers}');
      //Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        //Vehicle registration successful');
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 413) {
        //413 Request Entity Too Large');
        return {
          'success': false,
          'message':
              'Vehicle photo is too large. Please select a smaller image (max 2MB).',
        };
      } else {
        AppLogger.log(
          'Vehicle registration failed with status: ${response.statusCode}',
        );
        try {
          final error = jsonDecode(responseBody);
          return {
            'success': false,
            'message':
                error['message'] ??
                error['error'] ??
                'Vehicle registration failed',
          };
        } catch (parseError) {
          //Failed to parse error response: $parseError');
          return {
            'success': false,
            'message':
                'Vehicle registration failed. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e, stackTrace) {
      //REGISTER VEHICLE API ERROR: $e');
      //Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END REGISTER VEHICLE API DEBUG ===\n');
    }
  }

  // Update user location
  static Future<Map<String, dynamic>> updateLocation(
    String token,
    double lat,
    double lng,
  ) async {
    try {
      //=== UPDATE LOCATION DEBUG ===');
      //URL: $baseUrl${UrlConstants.updateLocation}');
      //Token: $token');
      //Latitude: $lat, Longitude: $lng');

      final locationPoint = 'POINT($lng $lat)';
      //Location Point: $locationPoint');

      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'location': locationPoint}),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      //UPDATE LOCATION ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END UPDATE LOCATION DEBUG ===\n');
    }
  }

  // Get active rides
  static Future<Map<String, dynamic>> getActiveRides(String token) async {
    try {
      //=== GET ACTIVE RIDES DEBUG ===');
      //URL: $baseUrl${UrlConstants.activeRides}');
      //Token: $token');
      //Request Body: {"status": "active"}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.activeRides}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': 'active'}),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        //Active rides found: ${data['rides']?.length ?? 0}');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        //Error getting active rides: $error');
        return {
          'success': false,
          'message':
              error['message'] ??
              error['error'] ??
              'Failed to get active rides',
        };
      }
    } catch (e) {
      //GET ACTIVE RIDES ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END GET ACTIVE RIDES DEBUG ===\n');
    }
  }

  // Start ride
  static Future<Map<String, dynamic>> startRide(
    String token,
    int rideId,
  ) async {
    try {
      //=== START RIDE DEBUG ===');
      //URL: $baseUrl${UrlConstants.startRide}/$rideId');
      //Token: $token');
      //Ride ID: $rideId');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.startRide}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        //Error starting ride: $error');
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to start ride',
        };
      }
    } catch (e) {
      //START RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END START RIDE DEBUG ===\n');
    }
  }

  // Update driver location during ride
  static Future<Map<String, dynamic>> updateDriverLocation(
    String token,
    int rideId,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/location/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to update location'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update driver location with POINT format
  static Future<Map<String, dynamic>> updateDriverLocationWithPoint(
    String token,
    int rideId,
    String pointLocation,
  ) async {
    try {
      //=== UPDATE DRIVER LOCATION WITH POINT ===');
      //URL: $baseUrl${UrlConstants.updateLocation}');
      //Token: ${token.substring(0, 20)}...');
      //Ride ID: $rideId');
      //Point Location: $pointLocation');

      final requestBody = {'location': pointLocation};
      //Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        //Location updated successfully with POINT format');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        //Location update failed: $error');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      //UPDATE DRIVER LOCATION ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END UPDATE DRIVER LOCATION WITH POINT ===\n');
    }
  }

  // Update driver location (general - when not in ride)
  static Future<Map<String, dynamic>> updateDriverLocationGeneral(
    String token,
    double lat,
    double lng,
  ) async {
    try {
      final locationPoint = 'POINT($lng $lat)';

      //=== GENERAL LOCATION UPDATE ===');
      //Raw coordinates: lat=$lat, lng=$lng');
      //POINT format: $locationPoint');
      //Token: ${token.substring(0, 20)}...');

      final requestBody = {'location': locationPoint};
      //Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'General location updated successfully with POINT format',
        );
        return {'success': true, 'data': data};
      } else {
        //General location update failed');
        return {'success': false, 'message': 'Failed to update location'};
      }
    } catch (e) {
      //GENERAL LOCATION UPDATE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END GENERAL LOCATION UPDATE ===\n');
    }
  }

  // Get earnings summary
  static Future<Map<String, dynamic>> getEarningsSummary(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/earnings/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get earnings summary',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Complete ride
  static Future<Map<String, dynamic>> completeRide(
    String token,
    int rideId,
  ) async {
    try {
      //=== COMPLETE RIDE DEBUG ===');
      //URL: $baseUrl${UrlConstants.completeRide}/$rideId');
      //Token: $token');
      //Ride ID: $rideId');

      // Get current location for end_location
      final position = await LocationService.getCurrentLocation();
      final endLocation = position != null
          ? 'POINT(${position.longitude} ${position.latitude})'
          : 'POINT(0 0)';

      final requestBody = {'end_location': endLocation};

      //Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.completeRide}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}');
      //Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        //Error completing ride: $error');
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      //COMPLETE RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END COMPLETE RIDE DEBUG ===\n');
    }
  }

  // Get driver vehicles
  static Future<Map<String, dynamic>> getVehicles(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> setPrimaryVehicle(
    dynamic id,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/vehicle/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? '${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user ratings
  static Future<Map<String, dynamic>> getUserRatings(
    String token,
    int userId,
  ) async {
    try {
      //=== GET USER RATINGS API ===', tag: 'API');
      final endpoint = '$baseUrl/users/$userId/ratings';
      //URL: $endpoint', tag: 'API');
      //User ID: $userId', tag: 'API');
      //Token: ${token.substring(0, 20)}...', tag: 'API');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //Response Status: ${response.statusCode}', tag: 'API');
      //Response Body: ${response.body}', tag: 'API');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        //Ratings fetched successfully', tag: 'API');
        return {'success': true, 'data': data};
      } else {
        //Failed to get ratings', tag: 'API');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get ratings',
        };
      }
    } catch (e) {
      //Exception in getUserRatings: $e', tag: 'API');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END GET USER RATINGS API ===\n', tag: 'API');
    }
  }

  // Send SOS emergency alert
  static Future<Map<String, dynamic>> sendSOS({
    required String token,
    required String location,
    required String locationAddress,
    required int rideId,
  }) async {
    try {
      //=== SEND SOS ALERT ===', tag: 'SOS');
      final endpoint = '$baseUrl/sos';
      //URL: $endpoint', tag: 'SOS');
      //Ride ID: $rideId', tag: 'SOS');
      //Location: $location', tag: 'SOS');
      //Address: $locationAddress', tag: 'SOS');

      final requestBody = {
        'location': location,
        'location_address': locationAddress,
        'ride_id': rideId,
      };

      //Request Body sos: ${jsonEncode(requestBody)}', tag: 'SOS');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      //Response Status: ${response.statusCode}', tag: 'SOS');
      //Response Bodysss: ${response.body}', tag: 'SOS');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        //SOS alert sent successfully', tag: 'SOS');
        return {'success': true, 'data': data};
      } else {
        //Failed to send SOS alert', tag: 'SOS');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['error'] ?? error['message'] ?? 'Failed to send SOS alert',
        };
      }
    } catch (e) {
      //Exception in sendSOS: $e', tag: 'SOS');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      //=== END SEND SOS ALERT ===\n', tag: 'SOS');
    }
  }
}
