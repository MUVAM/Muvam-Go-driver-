import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class UpdateLocationScreen extends StatefulWidget {
  const UpdateLocationScreen({super.key});

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = LatLng(6.5244, 3.3792);
  LatLng _currentLocation = LatLng(6.5244, 3.3792);
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  final List<String> _recentLocations = [
    'Victoria Island, Lagos',
    'Ikeja, Lagos',
    'Lekki Phase 1, Lagos',
    'Surulere, Lagos',
    'Yaba, Lagos',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = currentLocation;
        _selectedLocation = currentLocation;
        _markers = {
          Marker(
            markerId: MarkerId('selected'),
            position: _selectedLocation,
            infoWindow: InfoWindow(title: 'Current Location'),
          ),
        };
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation, zoom: 16.0),
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    AppLogger.log('=== MAP TAPPED ===');
    AppLogger.log(
      'Tapped position: ${position.latitude}, ${position.longitude}',
    );
    setState(() {
      _selectedLocation = position;
      _markers = {
        Marker(
          markerId: MarkerId('selected'),
          position: position,
          infoWindow: InfoWindow(title: 'Selected Location'),
        ),
      };
    });
  }

  Future<void> _updateLocation() async {
    AppLogger.log('=== UPDATING LOCATION ===');
    AppLogger.log(
      'Selected location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final result = await ApiService.updateLocation(
          token,
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        );

        if (result['success'] == true) {
          AppLogger.log('Location updated successfully');
          Navigator.pop(context);
          CustomFlushbar.showSuccess(
            context: context,
            message: 'Location updated successfully',
          );
        } else {
          AppLogger.log('Failed to update location: ${result['message']}');
          CustomFlushbar.showError(
            context: context,
            message: result['message'] ?? 'Failed to update location',
          );
        }
      }
    } catch (e) {
      AppLogger.log('Error updating location: $e');
      CustomFlushbar.showError(context: context, message: 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              Future.delayed(Duration(milliseconds: 500), () {
                _getCurrentLocation();
              });
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 16.0,
            ),
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 69.w,
                    height: 5.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onChanged: (value) {
                      _filterLocations(value);
                    },
                  ),
                  if (_showSuggestions && _locationSuggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: _locationSuggestions.map((location) {
                          return ListTile(
                            leading: Icon(Icons.location_on, size: 20.sp),
                            title: Text(
                              location['description'],
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            onTap: () => _selectLocation(location),
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(height: 20.h),
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  Text(
                    'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: _isLoading ? null : _updateLocation,
                    child: Container(
                      width: 353.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? Colors.grey
                            : Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Update Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterLocations(String query) {
    AppLogger.log('Filtering locations for: $query');

    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _locationSuggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=${UrlConstants.googleMapsApiKey}'
          '&components=country:ng';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;

        setState(() {
          _locationSuggestions = predictions
              .map(
                (prediction) => {
                  'place_id': prediction['place_id'],
                  'description': prediction['description'],
                },
              )
              .toList();
          _showSuggestions = _locationSuggestions.isNotEmpty;
        });
      } else {
        AppLogger.log('Places API error: ${response.statusCode}');
        _filterRecentLocations(query);
      }
    } catch (e) {
      AppLogger.log('Error searching places: $e');
      _filterRecentLocations(query);
    }
  }

  void _filterRecentLocations(String query) {
    final filtered = _recentLocations
        .where(
          (location) => location.toLowerCase().contains(query.toLowerCase()),
        )
        .map((location) => {'place_id': '', 'description': location})
        .toList();

    setState(() {
      _locationSuggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    AppLogger.log('Selected location: ${location['description']}');
    setState(() {
      _searchController.text = location['description'];
      _showSuggestions = false;
    });

    if (location['place_id'].isNotEmpty) {
      _getPlaceDetails(location['place_id']);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=geometry'
          '&key=${UrlConstants.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['result']['geometry'];
        final location = geometry['location'];

        final selectedLatLng = LatLng(
          location['lat'].toDouble(),
          location['lng'].toDouble(),
        );

        setState(() {
          _selectedLocation = selectedLatLng;
          _markers = {
            Marker(
              markerId: MarkerId('selected'),
              position: selectedLatLng,
              infoWindow: InfoWindow(title: 'Selected Location'),
            ),
          };
        });

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: selectedLatLng, zoom: 16.0),
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Error getting place details: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
