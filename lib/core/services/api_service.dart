import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class ApiService {
  static const String baseUrl = UrlConstants.baseUrl;

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      AppLogger.log('Sending OTP to: $phoneNumber');
      AppLogger.log('URL: $baseUrl${UrlConstants.sendOtp}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.sendOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Phone': phoneNumber}),
      );

      AppLogger.log('Response status: ${response.statusCode}');
      AppLogger.log('Response body: ${response.body}');

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
      AppLogger.log('Error: $e');
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
      AppLogger.log('Phone: $phoneNumber');
      AppLogger.log('OTP: $otp');
      AppLogger.log('URL: $baseUrl${UrlConstants.verifyOtp}');

      final requestBody = {'Phone': phoneNumber, 'Code': otp};
      AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.verifyOtp}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log('SUCCESS: OTP verified');
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('ERROR: OTP verification failed');
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? error['error'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      AppLogger.log('VERIFY OTP ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END VERIFY OTP DEBUG ===\n');
    }
  }

  // Register User
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String city,
    required String location,
    String serviceType = 'taxi',
  }) async {
    try {
      AppLogger.log('=== REGISTER USER DEBUG ===');
      final requestBody = {
        'first_name': firstName,
        'middle_name': middleName ?? '',
        'last_name': lastName,
        'email': email,
        'Phone': phoneNumber,
        'date_of_birth': dateOfBirth,
        'city': city,
        'role': 'driver',
        'service_type': 'taxi',
        'location': location,
      };
      AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.registerUser}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      AppLogger.log('REGISTER ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END REGISTER USER DEBUG ===\n');
    }
  }

  // Get nearby rides
  static Future<Map<String, dynamic>> getNearbyRides(String token) async {
    try {
      AppLogger.log('=== GET NEARBY RIDES DEBUG ===');
      AppLogger.log('URL: $baseUrl/rides/nearby');
      AppLogger.log('Token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/rides/nearby'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

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
      AppLogger.log('GET NEARBY RIDES ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END GET NEARBY RIDES DEBUG ===\n');
    }
  }

  // Accept ride
  static Future<Map<String, dynamic>> acceptRide(
    String token,
    int rideId,
  ) async {
    try {
      AppLogger.log('=== ACCEPT RIDE DEBUG ===');
      AppLogger.log('URL: $baseUrl/rides/accept/$rideId');
      AppLogger.log('Token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/accept/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

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
      AppLogger.log('ACCEPT RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END ACCEPT RIDE DEBUG ===\n');
    }
  }

  // Reject ride
  static Future<Map<String, dynamic>> rejectRide(
    String token,
    int rideId,
  ) async {
    try {
      AppLogger.log('=== REJECT RIDE DEBUG ===');
      AppLogger.log('URL: $baseUrl/rides/reject/$rideId');
      AppLogger.log('Token: $token');
      AppLogger.log('Ride ID: $rideId');

      final response = await http.post(
        Uri.parse('$baseUrl/rides/reject/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

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
      AppLogger.log('REJECT RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END REJECT RIDE DEBUG ===\n');
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
      AppLogger.log('=== DRIVER ONLINE STATUS DEBUG ===');
      AppLogger.log('URL: $baseUrl/driver/online');
      AppLogger.log('Token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/driver/online'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

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
      AppLogger.log('DRIVER STATUS ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END DRIVER ONLINE STATUS DEBUG ===\n');
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

  // Upload verification documents
  static Future<Map<String, dynamic>> uploadVerificationDocuments({
    required File driverLicense,
    required File vehicleRegistration,
    required File insurance,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/verification'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'driver_license_file',
          driverLicense.path,
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_registration_file',
          vehicleRegistration.path,
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath('insurrance_file', insurance.path),
      );

      AppLogger.log('=== UPLOAD DOCUMENTS DEBUG ===');
      AppLogger.log('URL: $baseUrl/users/verification');
      AppLogger.log('Token: $token');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'message':
              'Files are too large. Please select smaller images (max 2MB each) and try again.',
        };
      } else {
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
    } catch (e) {
      AppLogger.log('UPLOAD ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END UPLOAD DOCUMENTS DEBUG ===\n');
    }
  }

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
  }) async {
    try {
      AppLogger.log('=== REGISTER VEHICLE API DEBUG ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.registerVehicle}');
      AppLogger.log('Token: ${token.substring(0, 20)}...');
      AppLogger.log('Make: $make');
      AppLogger.log('Model Type: $modelType');
      AppLogger.log('Seats: $seats');
      AppLogger.log('Year: $year');
      AppLogger.log('License Number: $licenseNumber');
      AppLogger.log('Color: $color');
      AppLogger.log('License Plate: $licensePlate');
      AppLogger.log('Vehicle Photos: ${vehiclePhotos.length}');

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

      AppLogger.log('Request fields: ${request.fields}');
      AppLogger.log('Request headers: ${request.headers}');

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

      AppLogger.log('Files added to request: ${request.files.length}');
      AppLogger.log('Sending request...');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Headers: ${response.headers}');
      AppLogger.log('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.log('✅ Vehicle registration successful');
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 413) {
        AppLogger.log('❌ 413 Request Entity Too Large');
        return {
          'success': false,
          'message':
              'Vehicle photo is too large. Please select a smaller image (max 2MB).',
        };
      } else {
        AppLogger.log(
          '❌ Vehicle registration failed with status: ${response.statusCode}',
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
          AppLogger.log('❌ Failed to parse error response: $parseError');
          return {
            'success': false,
            'message':
                'Vehicle registration failed. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ REGISTER VEHICLE API ERROR: $e');
      AppLogger.log('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END REGISTER VEHICLE API DEBUG ===\n');
    }
  }

  // Update user location
  static Future<Map<String, dynamic>> updateLocation(
    String token,
    double lat,
    double lng,
  ) async {
    try {
      AppLogger.log('=== UPDATE LOCATION DEBUG ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.updateLocation}');
      AppLogger.log('Token: $token');
      AppLogger.log('Latitude: $lat, Longitude: $lng');

      final locationPoint = 'POINT($lat $lng)';
      AppLogger.log('Location Point: $locationPoint');

      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'location': locationPoint}),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

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
      AppLogger.log('UPDATE LOCATION ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END UPDATE LOCATION DEBUG ===\n');
    }
  }

  // Get active rides
  static Future<Map<String, dynamic>> getActiveRides(String token) async {
    try {
      AppLogger.log('=== GET ACTIVE RIDES DEBUG ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.activeRides}');
      AppLogger.log('Token: $token');
      AppLogger.log('Request Body: {"status": "active"}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.activeRides}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': 'active'}),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log('Active rides found: ${data['rides']?.length ?? 0}');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        AppLogger.log('Error getting active rides: ${error}');
        return {
          'success': false,
          'message':
              error['message'] ??
              error['error'] ??
              'Failed to get active rides',
        };
      }
    } catch (e) {
      AppLogger.log('GET ACTIVE RIDES ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END GET ACTIVE RIDES DEBUG ===\n');
    }
  }

  // Start ride
  static Future<Map<String, dynamic>> startRide(
    String token,
    int rideId,
  ) async {
    try {
      AppLogger.log('=== START RIDE DEBUG ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.startRide}/$rideId');
      AppLogger.log('Token: $token');
      AppLogger.log('Ride ID: $rideId');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.startRide}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        AppLogger.log('Error starting ride: ${error}');
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to start ride',
        };
      }
    } catch (e) {
      AppLogger.log('START RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END START RIDE DEBUG ===\n');
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
      AppLogger.log('=== UPDATE DRIVER LOCATION WITH POINT ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.updateLocation}');
      AppLogger.log('Token: ${token.substring(0, 20)}...');
      AppLogger.log('Ride ID: $rideId');
      AppLogger.log('Point Location: $pointLocation');
      
      final requestBody = {'location': pointLocation};
      AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log('✅ Location updated successfully with POINT format');
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        AppLogger.log('❌ Location update failed: ${error}');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      AppLogger.log('❌ UPDATE DRIVER LOCATION ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END UPDATE DRIVER LOCATION WITH POINT ===\n');
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
      
      AppLogger.log('=== GENERAL LOCATION UPDATE ===');
      AppLogger.log('📍 Raw coordinates: lat=$lat, lng=$lng');
      AppLogger.log('📍 POINT format: $locationPoint');
      AppLogger.log('📍 Token: ${token.substring(0, 20)}...');
      
      final requestBody = {'location': locationPoint};
      AppLogger.log('📍 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.put(
        Uri.parse('$baseUrl${UrlConstants.updateLocation}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log('📱 Response Status: ${response.statusCode}');
      AppLogger.log('📱 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.log('✅ General location updated successfully with POINT format');
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('❌ General location update failed');
        return {'success': false, 'message': 'Failed to update location'};
      }
    } catch (e) {
      AppLogger.log('❌ GENERAL LOCATION UPDATE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END GENERAL LOCATION UPDATE ===\n');
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
      AppLogger.log('=== COMPLETE RIDE DEBUG ===');
      AppLogger.log('URL: $baseUrl${UrlConstants.completeRide}/$rideId');
      AppLogger.log('Token: $token');
      AppLogger.log('Ride ID: $rideId');

      // Get current location for end_location
      final position = await LocationService.getCurrentLocation();
      final endLocation = position != null
          ? 'POINT(${position.longitude} ${position.latitude})'
          : 'POINT(0 0)';

      final requestBody = {'end_location': endLocation};

      AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl${UrlConstants.completeRide}/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        AppLogger.log('Error completing ride: ${error}');
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      AppLogger.log('COMPLETE RIDE ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      AppLogger.log('=== END COMPLETE RIDE DEBUG ===\n');
    }
  }
}
