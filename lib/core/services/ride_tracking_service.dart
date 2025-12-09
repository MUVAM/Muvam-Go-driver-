import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideTrackingService {
  static GoogleMapController? _mapController;
  static StreamSubscription<Position>? _positionStream;
  static Timer? _locationUpdateTimer;
  static Set<Marker> _markers = {};
  static Set<Polyline> _polylines = {};
  static PolylinePoints polylinePoints = PolylinePoints();
  static Map<String, dynamic>? _currentRide;

  // Parse PostGIS WKB format to LatLng
  static LatLng? _parsePostGISLocation(String? wkbHex) {
    if (wkbHex == null || wkbHex.isEmpty) {
      AppLogger.log('PostGIS location is null or empty');
      return null;
    }

    AppLogger.log('Parsing PostGIS WKB: $wkbHex (length: ${wkbHex.length})');

    try {
      // PostGIS WKB format for 50 chars: 0101000020E6100000[16 hex longitude][16 hex latitude]
      // Header: 18 chars, Longitude: 16 chars, Latitude: 16 chars = 50 total
      if (wkbHex.length != 50) {
        AppLogger.log(
          'WKB hex wrong length: ${wkbHex.length}, expected exactly 50',
        );
        return null;
      }

      // Extract coordinates: positions 18-33 (longitude), 34-49 (latitude)
      final lonHex = wkbHex.substring(18, 34); // 16 hex chars
      final latHex = wkbHex.substring(34, 50); // 16 hex chars

      AppLogger.log('Longitude hex: $lonHex');
      AppLogger.log('Latitude hex: $latHex');

      // Convert hex to double (little-endian IEEE 754)
      final lonBytes = _hexToBytes(lonHex);
      final latBytes = _hexToBytes(latHex);

      final longitude = _bytesToDouble(lonBytes);
      final latitude = _bytesToDouble(latBytes);

      AppLogger.log('✅ Parsed PostGIS: lat=$latitude, lng=$longitude');
      return LatLng(
        longitude,
        latitude,
      ); // Swap: PostGIS stores as lng,lat but LatLng expects lat,lng
    } catch (e) {
      AppLogger.log('❌ Error parsing PostGIS WKB: $e');
      return null;
    }
  }

  static List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes.reversed.toList(); // Reverse for little-endian
  }

  static double _bytesToDouble(List<int> bytes) {
    final uint8List = Uint8List.fromList(bytes);
    final buffer = uint8List.buffer.asByteData();
    return buffer.getFloat64(0, Endian.big);
  }

  static void setMapController(GoogleMapController controller) {
    _mapController = controller;
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

    // Debug: Print all ride keys and location values
    AppLogger.log('🔍 Available ride keys: ${ride.keys.toList()}');
    AppLogger.log('🔍 PickupLocation value: ${ride['PickupLocation']}');
    AppLogger.log('🔍 pickup_location value: ${ride['pickup_location']}');
    AppLogger.log('🔍 DestLocation value: ${ride['DestLocation']}');
    AppLogger.log('🔍 dest_location value: ${ride['dest_location']}');

    // Try multiple possible location key names
    LatLng? pickupLocation =
        _parsePostGISLocation(ride['PickupLocation']) ??
        _parsePostGISLocation(ride['pickup_location']);
    LatLng? destLocation =
        _parsePostGISLocation(ride['DestLocation']) ??
        _parsePostGISLocation(ride['dest_location']);

    // Fallback to lat/lng fields if PostGIS parsing fails
    if (pickupLocation == null) {
      final pickupLat =
          double.tryParse(ride['PickupLat']?.toString() ?? '0') ?? 0.0;
      final pickupLng =
          double.tryParse(ride['PickupLng']?.toString() ?? '0') ?? 0.0;
      pickupLocation = LatLng(pickupLat, pickupLng);
    }

    if (destLocation == null) {
      final destLat =
          double.tryParse(ride['DestLat']?.toString() ?? '0') ?? 0.0;
      final destLng =
          double.tryParse(ride['DestLng']?.toString() ?? '0') ?? 0.0;
      destLocation = LatLng(destLat, destLng);
    }

    AppLogger.log(
      'Pickup: ${pickupLocation.latitude}, ${pickupLocation.longitude}',
    );
    AppLogger.log(
      'Destination: ${destLocation.latitude}, ${destLocation.longitude}',
    );

    // Add pickup marker
    _markers.add(
      Marker(
        markerId: MarkerId('pickup'),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: ride['PickupAddress'] ?? 'Pickup point',
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
          snippet: ride['DestAddress'] ?? 'Drop-off point',
        ),
      ),
    );

    // Set initial camera to pickup location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLocation, 14),
      );
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

    // Start location tracking with timer (every 5 seconds for better real-time updates)
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        AppLogger.log('=== PERIODIC LOCATION UPDATE ===');
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

    if (rideStatus == 'accepted' || rideStatus == 'arrived') {
      // Going to pickup location - try multiple key names
      targetLocation =
          _parsePostGISLocation(ride['PickupLocation']) ??
          _parsePostGISLocation(ride['pickup_location']) ??
          LatLng(
            double.tryParse(ride['PickupLat']?.toString() ?? '0') ?? 0.0,
            double.tryParse(ride['PickupLng']?.toString() ?? '0') ?? 0.0,
          );
      routeType = 'pickup';
      AppLogger.log(
        'Route to PICKUP: ${targetLocation.latitude}, ${targetLocation.longitude}',
      );
    } else {
      // Going to destination - try multiple key names
      targetLocation =
          _parsePostGISLocation(ride['DestLocation']) ??
          _parsePostGISLocation(ride['dest_location']) ??
          LatLng(
            double.tryParse(ride['DestLat']?.toString() ?? '0') ?? 0.0,
            double.tryParse(ride['DestLng']?.toString() ?? '0') ?? 0.0,
          );
      routeType = 'destination';
      AppLogger.log(
        'Route to DESTINATION: ${targetLocation.latitude}, ${targetLocation.longitude}',
      );
    }

    // Draw route from driver to target
    await _drawRoute(driverLocation, targetLocation, onUpdate, routeType);

    // Calculate ETA
    final distance = _calculateDistance(driverLocation, targetLocation);
    final eta = _calculateETA(distance);
    final locationName = rideStatus == 'accepted' || rideStatus == 'arrived'
        ? ride['PickupAddress'] ?? 'Pickup location'
        : ride['DestAddress'] ?? 'Destination';

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
      onUpdate(_markers, _polylines);
    } catch (e) {
      AppLogger.log('❌ Error drawing route: $e');
      // Fallback to straight line on error
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
      onUpdate(_markers, _polylines);
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
        AppLogger.log('Sending location update to backend...');
        final result = await ApiService.updateDriverLocation(
          token,
          rideId,
          lat,
          lng,
        );
        if (result['success'] == true) {
          AppLogger.log('✅ Location update sent successfully');
        } else {
          AppLogger.log('❌ Location update failed: ${result['message']}');
        }
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
}
