import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/wkb_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideTrackingService {
  static GoogleMapController? _mapController;
  static StreamSubscription<Position>? _positionStream;
  static Timer? _locationUpdateTimer;
  static Set<Marker> _markers = {};
  static Set<Polyline> _polylines = {};
  static PolylinePoints polylinePoints = PolylinePoints();
  static Map<String, dynamic>? _currentRide;

  // Parse WKB location data using the dedicated WKB decoder
  static LatLng? _parseWKBLocation(String? wkbHex) {
    if (wkbHex == null || wkbHex.isEmpty) {
      AppLogger.log('WKB location is null or empty');
      return null;
    }

    AppLogger.log('🔍 Parsing WKB: $wkbHex (length: ${wkbHex.length})');

    try {
      final coordinates = WKBDecoder.decodePoint(wkbHex);
      AppLogger.log('🔍 WKB decoder result: $coordinates');
      
      if (coordinates != null) {
        final rawLat = coordinates['latitude']!;
        final rawLng = coordinates['longitude']!;
        AppLogger.log('🔍 WKB raw decoded: lat=$rawLat, lng=$rawLng');
        
        // For Nigeria (Enugu/Nsukka area):
        // Latitude should be around 6.8-7.4 (North)
        // Longitude should be around 7.0-7.5 (East)
        
        double finalLat, finalLng;
        
        // If rawLat is around 7+ and rawLng is around 6-7, they're swapped
        if (rawLat > 7.0 && rawLng >= 6.0 && rawLng <= 7.5) {
          AppLogger.log('🔄 Coordinates swapped detected (Nigeria region), correcting');
          finalLat = rawLng;  // Use longitude as latitude
          finalLng = rawLat;  // Use latitude as longitude
        } else {
          finalLat = rawLat;
          finalLng = rawLng;
        }
        
        AppLogger.log('✅ Final coordinates: lat=$finalLat, lng=$finalLng');
        AppLogger.log('🌍 Location check: ${_getLocationDescription(finalLat, finalLng)}');
        
        return LatLng(finalLat, finalLng);
      } else {
        AppLogger.log('❌ Failed to decode WKB coordinates - decoder returned null');
        return null;
      }
    } catch (e) {
      AppLogger.log('❌ Error parsing WKB: $e');
      return null;
    }
  }
  
  // Helper to describe location for debugging
  static String _getLocationDescription(double lat, double lng) {
    if (lat >= 6.0 && lat <= 8.0 && lng >= 6.5 && lng <= 8.0) {
      return 'Nigeria (Enugu/Nsukka region) ✅';
    } else if (lat >= 6.0 && lat <= 7.0 && lng >= 3.0 && lng <= 4.0) {
      return 'Nigeria (Lagos region)';
    } else {
      return 'Unknown region - coordinates may be incorrect';
    }
  }

  // Parse lat/lng from separate fields with validation
  static LatLng _parseLatLngFromFields(Map<String, dynamic> data, String latKey, String lngKey) {
    final lat = double.tryParse(data[latKey]?.toString() ?? '0') ?? 0.0;
    final lng = double.tryParse(data[lngKey]?.toString() ?? '0') ?? 0.0;
    return LatLng(lat, lng);
  }

  // Extract location from different data formats
  static LatLng _extractLocation(Map<String, dynamic> data, String type) {
    AppLogger.log('🔍 EXTRACTING LOCATION: type=$type');
    AppLogger.log('   Available keys: ${data.keys.toList()}');
    
    if (type == 'pickup') {
      final pickupWKB = data['PickupLocation'];
      AppLogger.log('   PickupLocation WKB: $pickupWKB');
      final result = _parseWKBLocation(pickupWKB);
      AppLogger.log('   Parsed pickup result: $result');
      return result ?? LatLng(0.0, 0.0);
    } else {
      final destWKB = data['DestLocation'];
      AppLogger.log('   DestLocation WKB: $destWKB');
      final result = _parseWKBLocation(destWKB);
      AppLogger.log('   Parsed dest result: $result');
      return result ?? LatLng(0.0, 0.0);
    }
  }

  // Parse coordinate array [lat, lng]
  static LatLng? _parseCoordinateArray(dynamic coordinates) {
    if (coordinates is List && coordinates.length >= 2) {
      final lat = double.tryParse(coordinates[0].toString());
      final lng = double.tryParse(coordinates[1].toString());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  // Extract passenger name from different formats
  static String _extractPassengerName(Map<String, dynamic> data) {
    // WebSocket: data.PassengerName
    if (data['PassengerName'] != null) {
      return data['PassengerName'].toString();
    }
    
    // Nearby/Active rides: Passenger.first_name + Passenger.last_name
    if (data['Passenger'] != null) {
      final passenger = data['Passenger'] as Map<String, dynamic>;
      final firstName = passenger['first_name']?.toString() ?? '';
      final lastName = passenger['last_name']?.toString() ?? '';
      return '$firstName$lastName'.trim();
    }
    
    return 'Unknown Passenger';
  }

  // Extract address from different formats
  static String _extractAddress(Map<String, dynamic> data, String type) {
    if (type == 'pickup') {
      // All three sources have PickupAddress
      return data['PickupAddress']?.toString() ?? 'Pickup Location';
    } else {
      // All three sources have DestAddress
      return data['DestAddress']?.toString() ?? 'Destination';
    }
  }

  // Validate if coordinates are reasonable
  static bool _isValidLocation(LatLng location) {
    return location.latitude != 0.0 && 
           location.longitude != 0.0 &&
           location.latitude.abs() <= 90 &&
           location.longitude.abs() <= 180;
  }

  static void setMapController(GoogleMapController controller) {
    _mapController = controller;
    AppLogger.log('🗺️ Map controller set in RideTrackingService');
    
    // If there's an active ride, prioritize centering on it
    if (_currentRide != null && _markers.isNotEmpty) {
      AppLogger.log('🎯 Active ride detected, centering on ride location');
      // Small delay to ensure map is ready
      Future.delayed(Duration(milliseconds: 500), () {
        _centerMapOnRide();
      });
    } else {
      AppLogger.log('📍 No active ride, centering on current location');
      // Center map on current location when controller is set
      _centerMapOnCurrentLocation();
    }
  }
  
  // Helper method to center map on active ride
  static void _centerMapOnRide() {
    if (_mapController == null || _currentRide == null) return;
    
    try {
      // Find pickup marker to center on
      Marker? pickupMarker;
      try {
        pickupMarker = _markers.firstWhere(
          (marker) => marker.markerId.value == 'pickup',
        );
      } catch (e) {
        pickupMarker = _markers.isNotEmpty ? _markers.first : null;
      }
      
      if (pickupMarker != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(pickupMarker.position, 14),
        );
        AppLogger.log('✅ Map centered on active ride pickup location');
      }
    } catch (e) {
      AppLogger.log('❌ Error centering map on ride: $e');
    }
  }

  // Center map on current location
  static Future<void> _centerMapOnCurrentLocation() async {
    if (_mapController == null) return;
    
    try {
      AppLogger.log('📍 Getting current location to center map');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final currentLocation = LatLng(position.latitude, position.longitude);
      AppLogger.log('📍 Current location: ${currentLocation.latitude}, ${currentLocation.longitude}');
      AppLogger.log('🌍 Location: ${_getLocationDescription(currentLocation.latitude, currentLocation.longitude)}');
      
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );
      
      AppLogger.log('✅ Map centered on current location');
    } catch (e) {
      AppLogger.log('❌ Failed to get current location: $e');
      // Fallback to Nigeria default if location fails
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(6.8724, 7.4077), 12),
      );
    }
  }

  // Public method to center map on current location (can be called from UI)
  static Future<void> centerMapOnCurrentLocation() async {
    await _centerMapOnCurrentLocation();
  }

  static Set<Marker> get markers => _markers;
  static Set<Polyline> get polylines => _polylines;

  static Future<void> startRideTracking({
    required Map<String, dynamic> ride,
    required Function(Set<Marker>, Set<Polyline>) onUpdate,
    required Function(String, String) onTimeUpdate,
  }) async {
    AppLogger.log('=== STARTING RIDE TRACKING ===');
    AppLogger.log('Ride ID: ${ride['ID']}');
    AppLogger.log('Ride Status: ${ride['Status']}');

    // Stop any existing tracking first
    stopTracking();

    // Clear and reset everything
    _markers.clear();
    _polylines.clear();
    _currentRide = ride;

    // COMPREHENSIVE DATA LOGGING FOR ALL THREE SOURCES
    AppLogger.log('🚨🚨🚨 COMPLETE DATA STRUCTURE ANALYSIS 🚨🚨🚨');
    AppLogger.log('📊 FULL RIDE OBJECT: ${ride.toString()}');
    AppLogger.log('🔑 TOP LEVEL KEYS: ${ride.keys.toList()}');
    
    // Check if this is WebSocket/Nearby format (has 'data' field)
    if (ride['data'] != null) {
      AppLogger.log('📡 DATA SOURCE: WebSocket/Nearby Rides (has nested data)');
      final data = ride['data'] as Map<String, dynamic>;
      AppLogger.log('🔑 NESTED DATA KEYS: ${data.keys.toList()}');
      AppLogger.log('📊 NESTED DATA CONTENT: ${data.toString()}');
      
      // Log all possible passenger name fields
      AppLogger.log('👤 PASSENGER FIELDS:');
      AppLogger.log('   PassengerName: ${data['PassengerName']}');
      AppLogger.log('   passenger_name: ${data['passenger_name']}');
      AppLogger.log('   name: ${data['name']}');
      AppLogger.log('   user_name: ${data['user_name']}');
      
      // Log all possible location fields
      AppLogger.log('📍 LOCATION FIELDS:');
      AppLogger.log('   PickupLocation: ${data['PickupLocation']}');
      AppLogger.log('   pickup_location: ${data['pickup_location']}');
      AppLogger.log('   DestLocation: ${data['DestLocation']}');
      AppLogger.log('   dest_location: ${data['dest_location']}');
      AppLogger.log('   PickupLat: ${data['PickupLat']}');
      AppLogger.log('   PickupLng: ${data['PickupLng']}');
      AppLogger.log('   pickup_lat: ${data['pickup_lat']}');
      AppLogger.log('   pickup_lng: ${data['pickup_lng']}');
      AppLogger.log('   DestLat: ${data['DestLat']}');
      AppLogger.log('   DestLng: ${data['DestLng']}');
      AppLogger.log('   dest_lat: ${data['dest_lat']}');
      AppLogger.log('   dest_lng: ${data['dest_lng']}');
      
      // Log address fields
      AppLogger.log('🏠 ADDRESS FIELDS:');
      AppLogger.log('   PickupAddress: ${data['PickupAddress']}');
      AppLogger.log('   pickup_address: ${data['pickup_address']}');
      AppLogger.log('   DestAddress: ${data['DestAddress']}');
      AppLogger.log('   dest_address: ${data['dest_address']}');
    } else {
      AppLogger.log('🗂️ DATA SOURCE: Active Rides API (direct structure)');
      
      // Log all possible passenger name fields
      AppLogger.log('👤 PASSENGER FIELDS:');
      AppLogger.log('   PassengerName: ${ride['PassengerName']}');
      AppLogger.log('   passenger_name: ${ride['passenger_name']}');
      AppLogger.log('   name: ${ride['name']}');
      AppLogger.log('   user_name: ${ride['user_name']}');
      AppLogger.log('   User: ${ride['User']}');
      AppLogger.log('   user: ${ride['user']}');
      
      // Log all possible location fields
      AppLogger.log('📍 LOCATION FIELDS:');
      AppLogger.log('   PickupLocation: ${ride['PickupLocation']}');
      AppLogger.log('   pickup_location: ${ride['pickup_location']}');
      AppLogger.log('   DestLocation: ${ride['DestLocation']}');
      AppLogger.log('   dest_location: ${ride['dest_location']}');
      AppLogger.log('   PickupLat: ${ride['PickupLat']}');
      AppLogger.log('   PickupLng: ${ride['PickupLng']}');
      AppLogger.log('   pickup_lat: ${ride['pickup_lat']}');
      AppLogger.log('   pickup_lng: ${ride['pickup_lng']}');
      AppLogger.log('   DestLat: ${ride['DestLat']}');
      AppLogger.log('   DestLng: ${ride['DestLng']}');
      AppLogger.log('   dest_lat: ${ride['dest_lat']}');
      AppLogger.log('   dest_lng: ${ride['dest_lng']}');
      
      // Log address fields
      AppLogger.log('🏠 ADDRESS FIELDS:');
      AppLogger.log('   PickupAddress: ${ride['PickupAddress']}');
      AppLogger.log('   pickup_address: ${ride['pickup_address']}');
      AppLogger.log('   DestAddress: ${ride['DestAddress']}');
      AppLogger.log('   dest_address: ${ride['dest_address']}');
      
      // Check for nested user object
      if (ride['User'] != null) {
        AppLogger.log('👤 NESTED USER OBJECT: ${ride['User']}');
      }
      if (ride['user'] != null) {
        AppLogger.log('👤 NESTED user OBJECT: ${ride['user']}');
      }
    }
    AppLogger.log('🚨🚨🚨 END DATA STRUCTURE ANALYSIS 🚨🚨🚨');
    
    // Extract data from nested structure if it exists (WebSocket/Nearby format)
    final rideData = ride['data'] ?? ride;

    // Try multiple possible location key names and formats
    LatLng pickupLocation = _extractLocation(rideData, 'pickup');
    LatLng destLocation = _extractLocation(rideData, 'destination');

    // Validate locations
    if (!_isValidLocation(pickupLocation)) {
      AppLogger.log('❌ Invalid pickup location: ${pickupLocation.latitude}, ${pickupLocation.longitude}');
      return;
    }
    if (!_isValidLocation(destLocation)) {
      AppLogger.log('❌ Invalid destination location: ${destLocation.latitude}, ${destLocation.longitude}');
      return;
    }

    AppLogger.log(
      'Pickup: ${pickupLocation.latitude}, ${pickupLocation.longitude}',
    );
    AppLogger.log('🌍 Pickup location: ${_getLocationDescription(pickupLocation.latitude, pickupLocation.longitude)}');
    AppLogger.log(
      'Destination: ${destLocation.latitude}, ${destLocation.longitude}',
    );
    AppLogger.log('🌍 Destination location: ${_getLocationDescription(destLocation.latitude, destLocation.longitude)}');

    // Add pickup marker
    _markers.add(
      Marker(
        markerId: MarkerId('pickup'),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: '${_extractPassengerName(rideData)} - ${_extractAddress(rideData, 'pickup')}',
        ),
      ),
    );

    // Add destination marker
    _markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: destLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: '${_extractPassengerName(rideData)} - ${_extractAddress(rideData, 'destination')}',
        ),
      ),
    );

    // Set initial camera to pickup location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLocation, 14),
      );
      AppLogger.log('✅ Map centered on pickup location during tracking start');
    } else {
      AppLogger.log('⚠️ Map controller not available during tracking start');
    }

    // Get initial driver location and draw route immediately
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      AppLogger.log(
        'Initial driver location: ${position.latitude}, ${position.longitude}',
      );

      await _updateDriverLocation(position, ride, onUpdate, onTimeUpdate);
    } catch (e) {
      AppLogger.log('Failed to get initial location: $e');
      // Still show markers even if location fails
      onUpdate(_markers, _polylines);

      // Zoom to pickup location as fallback
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(pickupLocation, 13),
        );
      }
    }

    // Start location tracking with timer (every 20 seconds)
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 20), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        AppLogger.log('=== PERIODIC LOCATION UPDATE (20s interval) ===');
        AppLogger.log(
          'Driver Location: ${position.latitude}, ${position.longitude}',
        );
        AppLogger.log('Ride Status: ${_currentRide?['Status']}');

        await _updateDriverLocation(
          position,
          _currentRide ?? ride,
          onUpdate,
          onTimeUpdate,
        );
      } catch (e) {
        AppLogger.log('Failed to get location: $e');
      }
    });

    // Also start position stream for real-time map updates (reduced distance filter for better tracking)
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20, // Update every 20 meters
          ),
        ).listen((Position position) {
          AppLogger.log('=== STREAM LOCATION UPDATE ===');
          AppLogger.log(
            'Driver Location: ${position.latitude}, ${position.longitude}',
          );

          _updateDriverLocation(
            position,
            _currentRide ?? ride,
            onUpdate,
            onTimeUpdate,
          );
        });

    AppLogger.log('=== RIDE TRACKING STARTED ===');
    AppLogger.log(
      'Map will focus on pickup location and show route with polylines',
    );
    AppLogger.log(
      'Green solid line = Route to pickup, Blue dashed line = Route to destination\n',
    );
  }

  static Future<void> _updateDriverLocation(
    Position position,
    Map<String, dynamic> ride,
    Function(Set<Marker>, Set<Polyline>) onUpdate,
    Function(String, String) onTimeUpdate,
  ) async {
    // Check if tracking is still active
    if (_currentRide == null) {
      AppLogger.log('Tracking stopped, ignoring location update');
      return;
    }

    final driverLocation = LatLng(position.latitude, position.longitude);

    AppLogger.log(
      'Updating driver location: ${driverLocation.latitude}, ${driverLocation.longitude}',
    );
    AppLogger.log('🌍 Driver location check: ${_getLocationDescription(driverLocation.latitude, driverLocation.longitude)}');
    
    // Log the ride data structure being used for updates
    AppLogger.log('🚨🚨🚨 UPDATE DRIVER LOCATION - RIDE DATA STRUCTURE 🚨🚨🚨');
    AppLogger.log('📊 RIDE OBJECT FOR UPDATE: ${ride.toString()}');
    AppLogger.log('🔑 RIDE KEYS FOR UPDATE: ${ride.keys.toList()}');
    AppLogger.log('🚨🚨🚨 END UPDATE RIDE DATA STRUCTURE 🚨🚨🚨');

    // Send location update to backend
    await _sendLocationUpdate(
      ride['ID'],
      position.latitude,
      position.longitude,
    );

    // Update driver marker with custom car image
    _markers.removeWhere((marker) => marker.markerId.value == 'driver');

    // Create custom car icon
    final carIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(80, 38)),
      'assets/images/locationcar.png',
    );

    _markers.add(
      Marker(
        markerId: MarkerId('driver'),
        position: driverLocation,
        icon: carIcon,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: 'Driver position',
        ),
        rotation: 0, // You can add bearing here if available
      ),
    );

    final rideStatus = ride['Status'] ?? 'accepted';
    LatLng targetLocation;
    String routeType;

    // Extract data from nested structure if it exists
    final rideData = ride['data'] ?? ride;
    AppLogger.log('🔍 UPDATE: Using ${ride['data'] != null ? 'nested data' : 'direct ride'} structure');
    
    if (rideStatus == 'accepted' || rideStatus == 'arrived') {
      // Going to pickup location
      targetLocation = _extractLocation(rideData, 'pickup');
      routeType = 'pickup';
      AppLogger.log(
        'Route to PICKUP: ${targetLocation.latitude}, ${targetLocation.longitude}',
      );
    } else {
      // Going to destination
      targetLocation = _extractLocation(rideData, 'destination');
      routeType = 'destination';
      AppLogger.log(
        'Route to DESTINATION: ${targetLocation.latitude}, ${targetLocation.longitude}',
      );
    }

    // Validate target location before drawing route
    if (!_isValidLocation(targetLocation)) {
      AppLogger.log('❌ Invalid target location, skipping route drawing');
      onUpdate(_markers, _polylines);
      return;
    }

    // Draw route from driver to target (only if both locations are valid)
    if (_isValidLocation(driverLocation) && _isValidLocation(targetLocation)) {
      await _drawRoute(driverLocation, targetLocation, onUpdate, routeType);
    } else {
      AppLogger.log('❌ Skipping route drawing due to invalid coordinates');
      onUpdate(_markers, _polylines);
    }

    // Calculate ETA
    final distance = _calculateDistance(driverLocation, targetLocation);
    final eta = _calculateETA(distance);
    final locationName = rideStatus == 'accepted' || rideStatus == 'arrived'
        ? _extractAddress(rideData, 'pickup')
        : _extractAddress(rideData, 'destination');

    AppLogger.log(
      'ETA: $eta to $locationName (Distance: ${(distance / 1000).toStringAsFixed(2)}km)',
    );

    onTimeUpdate(eta, locationName);

    // Update camera to show both driver and target
    _updateCamera(driverLocation, targetLocation);
  }

  static Future<void> _drawRoute(
    LatLng start,
    LatLng end,
    Function(Set<Marker>, Set<Polyline>) onUpdate,
    String routeType,
  ) async {
    // Validate coordinates before attempting to draw route
    if (!_isValidLocation(start) || !_isValidLocation(end)) {
      AppLogger.log('❌ Invalid coordinates for route drawing');
      AppLogger.log('Start: ${start.latitude}, ${start.longitude}');
      AppLogger.log('End: ${end.latitude}, ${end.longitude}');
      return;
    }

    try {
      AppLogger.log(
        '🗺️ Drawing route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}',
      );

      List<LatLng> polylineCoordinates = [];

      // Get route points using polyline_points with timeout
      PolylineResult result = await polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: UrlConstants.googleMapsApiKey,
            request: PolylineRequest(
              origin: PointLatLng(start.latitude, start.longitude),
              destination: PointLatLng(end.latitude, end.longitude),
              mode: TravelMode.driving,
              optimizeWaypoints: true,
            ),
          )
          .timeout(Duration(seconds: 10));

      if (result.points.isNotEmpty) {
        AppLogger.log('✅ Route API returned ${result.points.length} points');
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        AppLogger.log(
          '⚠️ Route API returned no points, error: ${result.errorMessage}',
        );
        // Fallback to straight line if API fails
        polylineCoordinates.add(start);
        polylineCoordinates.add(end);
      }

      // Clear existing polylines
      _polylines.clear();

      // Use main app color for all polylines (solid)
      const Color mainColor = Color(0xff2A8359); // Main app color

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$routeType'),
          points: polylineCoordinates,
          color: mainColor,
          width: 6, // Good visibility
          patterns: [], // Solid line (no patterns)
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );

      AppLogger.log(
        '✅ Polyline created with ${polylineCoordinates.length} points (${routeType})',
      );
      AppLogger.log('🔍 Polyline details: ID=${_polylines.first.polylineId.value}, Points=${_polylines.first.points.length}, Color=${_polylines.first.color}');
      AppLogger.log('🔍 Total markers: ${_markers.length}, Total polylines: ${_polylines.length}');
      onUpdate(_markers, _polylines);
    } catch (e) {
      AppLogger.log('❌ Error drawing route: $e');
        // Only create fallback if coordinates are valid
      if (_isValidLocation(start) && _isValidLocation(end)) {
        List<LatLng> fallbackCoordinates = [start, end];
        _polylines.clear();

        const Color mainColor = Color(0xff2A8359); // Main app color

        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_fallback'),
            points: fallbackCoordinates,
            color: mainColor,
            width: 6,
            patterns: [], // Solid line
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
        AppLogger.log('⚠️ Fallback straight-line polyline created');
        AppLogger.log('🔍 Fallback polyline: Points=${_polylines.first.points.length}, Color=${_polylines.first.color}');
        onUpdate(_markers, _polylines);
      }
    }
  }

  static double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  static String _calculateETA(double distanceInMeters) {
    // Assume average speed of 25 km/h in city (more realistic with traffic)
    final distanceInKm = distanceInMeters / 1000;
    final timeInHours = distanceInKm / 25;
    final timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes < 1) return '< 1 min';
    if (timeInMinutes == 1) return '1 min';
    return '$timeInMinutes mins';
  }

  static void _updateCamera(LatLng driverLocation, LatLng targetLocation) {
    if (_mapController != null && _currentRide != null) {
      try {
        // Calculate distance between points to determine appropriate zoom
        final distance = _calculateDistance(driverLocation, targetLocation);

        if (distance < 1000) {
          // If very close (< 1km), zoom to driver location
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(driverLocation, 16),
          );
        } else if (distance < 5000) {
          // If moderately close (< 5km), show both with good zoom
          final bounds = LatLngBounds(
            southwest: LatLng(
              min(driverLocation.latitude, targetLocation.latitude) - 0.01,
              min(driverLocation.longitude, targetLocation.longitude) - 0.01,
            ),
            northeast: LatLng(
              max(driverLocation.latitude, targetLocation.latitude) + 0.01,
              max(driverLocation.longitude, targetLocation.longitude) + 0.01,
            ),
          );
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        } else {
          // For longer distances, use larger bounds
          final bounds = LatLngBounds(
            southwest: LatLng(
              min(driverLocation.latitude, targetLocation.latitude) - 0.02,
              min(driverLocation.longitude, targetLocation.longitude) - 0.02,
            ),
            northeast: LatLng(
              max(driverLocation.latitude, targetLocation.latitude) + 0.02,
              max(driverLocation.longitude, targetLocation.longitude) + 0.02,
            ),
          );
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 80),
          );
        }

        AppLogger.log(
          'Camera updated for distance: ${(distance / 1000).toStringAsFixed(2)}km',
        );
      } catch (e) {
        AppLogger.log('Error updating camera: $e');
        // Don't attempt fallback if controller is disposed
      }
    }
  }

  static Future<void> _sendLocationUpdate(
    int rideId,
    double lat,
    double lng,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        // Format location as POINT(longitude latitude) for PostGIS
        final pointLocation = 'POINT($lng $lat)';
        
        AppLogger.log('=== SENDING LOCATION UPDATE ===');
        AppLogger.log('📍 Raw coordinates: lat=$lat, lng=$lng');
        AppLogger.log('📍 POINT format: $pointLocation');
        AppLogger.log('📍 Ride ID: $rideId');
        AppLogger.log('📍 Token: ${token.substring(0, 20)}...');
        
        final result = await ApiService.updateDriverLocationWithPoint(
          token,
          rideId,
          pointLocation,
        );
        
        AppLogger.log('📱 API Response: $result');
        
        if (result['success'] == true) {
          AppLogger.log('✅ Location update sent successfully in POINT format');
        } else {
          AppLogger.log('❌ Location update failed: ${result['message']}');
        }
      } else {
        AppLogger.log('❌ No auth token found for location update');
      }
    } catch (e) {
      AppLogger.log('❌ Failed to send location update: $e');
    }
    AppLogger.log('=== END LOCATION UPDATE ===\n');
  }

  static void stopTracking() {
    AppLogger.log('=== STOPPING RIDE TRACKING ===');

    _positionStream?.cancel();
    _positionStream = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _currentRide = null;
    _mapController = null; // Clear map controller reference

    // Clear all markers and polylines
    _markers.clear();
    _polylines.clear();

    AppLogger.log('🛑 Location tracking stopped');
    AppLogger.log('🧹 Markers and polylines cleared');
    AppLogger.log('=== RIDE TRACKING STOPPED ===\n');
  }

  // Update ride status (called when ride status changes)
  static void updateRideStatus(Map<String, dynamic> updatedRide) {
    if (_currentRide != null) {
      AppLogger.log('=== UPDATING RIDE STATUS ===');
      AppLogger.log('Old Status: ${_currentRide!['Status']}');
      AppLogger.log('New Status: ${updatedRide['Status']}');

      _currentRide = updatedRide;

      AppLogger.log('=== RIDE STATUS UPDATED ===\n');
    }
  }

  // Handle WebSocket location updates with WKB decoding
  static void handleWebSocketLocationUpdate(
    Map<String, dynamic> locationData,
    Function(Set<Marker>, Set<Polyline>) onUpdate,
    Function(String, String) onTimeUpdate,
  ) {
    if (_currentRide == null) {
      AppLogger.log('No active ride, ignoring WebSocket location update');
      return;
    }

    AppLogger.log('=== WEBSOCKET LOCATION UPDATE ===');
    AppLogger.log('🚨🚨🚨 WEBSOCKET LOCATION DATA STRUCTURE 🚨🚨🚨');
    AppLogger.log('📊 FULL LOCATION OBJECT: ${locationData.toString()}');
    AppLogger.log('🔑 LOCATION DATA KEYS: ${locationData.keys.toList()}');
    AppLogger.log('🚨🚨🚨 END WEBSOCKET LOCATION DATA STRUCTURE 🚨🚨🚨');

    try {
      // Extract WKB location data from WebSocket message
      final wkbLocation = locationData['location'] ?? locationData['driver_location'];
      if (wkbLocation != null) {
        final coordinates = _parseWKBLocation(wkbLocation);
        if (coordinates != null) {
          AppLogger.log('Decoded WebSocket location: ${coordinates.latitude}, ${coordinates.longitude}');
          
          // Create a Position object from the decoded coordinates
          final position = Position(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          
          // Update driver location using existing logic
          _updateDriverLocation(position, _currentRide!, onUpdate, onTimeUpdate);
        } else {
          AppLogger.log('Failed to decode WKB location from WebSocket');
        }
      } else {
        AppLogger.log('No location data found in WebSocket message');
      }
    } catch (e) {
      AppLogger.log('Error handling WebSocket location update: $e');
    }
    
    AppLogger.log('=== END WEBSOCKET LOCATION UPDATE ===\n');
  }
}
