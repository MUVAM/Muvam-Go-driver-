import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/services/ride_tracking_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam_rider/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/communication/presentation/screens/chat_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/wallet_screen.dart';
import 'package:muvam_rider/features/home/data/provider/driver_provider.dart';
import 'package:muvam_rider/features/home/presentation/widgets/ride_info_widget.dart';
import 'package:muvam_rider/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam_rider/features/referral/presentation/screens/referral_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_completed_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBottomSheetVisible = true;
  final bool _showDestinationField = false;
  int _currentIndex = 0;
  int? selectedVehicle;
  int? selectedDelivery;
  String selectedPaymentMethod = 'Pay in car';
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedCancelReason;
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(6.5244, 3.3792); // Lagos default
  Set<Marker> _mapMarkers = {};
  Set<Polyline> _mapPolylines = {};
  String _currentETA = '';
  String _currentLocationName = '';
  Map<String, dynamic>? _activeRide;
  bool _isRideSheetVisible = true; // Track ride sheet visibility
  List<String> recentLocations = [
    'Nsukka, Ogige',
    'Holy ghost Enugu',
    'Abakpa, Enugu',
  ];
  final WebSocketService _webSocketService = WebSocketService();
  List<Map<String, dynamic>> _nearbyRides = [];
  int _currentRideIndex = 0;
  bool _hasActiveRequest = false;
  Timer? _rideCheckTimer;
  Timer? _sessionCheckTimer;
  Timer? _locationUpdateTimer;
  Map<String, dynamic> _earningsData = {
    'total_earnings': 0,
    'total_rides': 0,
    'total_rides_completed': 0,
  };

  void _showContactBottomSheet() {
    Navigator.pop(context); // Close drawer
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contact us', style: ConstTextStyles.addHomeTitle),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Image.asset(
                ConstImages.phoneCall,
                width: 22.w,
                height: 22.h,
              ),
              title: Text('Via Call', style: ConstTextStyles.contactOption),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              leading: Image.asset(
                ConstImages.whatsapp,
                width: 22.w,
                height: 22.h,
              ),
              title: Text('Via WhatsApp', style: ConstTextStyles.contactOption),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _webSocketService.onRideRequest = null;
    _webSocketService.disconnect();
    _rideCheckTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
    RideTrackingService.stopTracking();
    super.dispose();
  }

  void _initializeServices() async {
    print('=== INITIALIZING HOME SCREEN SERVICES ===');

    // Check session expiration first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isExpired = await authProvider.isSessionExpired();

    if (isExpired) {
      print('🔒 Session expired, redirecting to login...');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RiderSignupSelectionScreen()),
        (route) => false,
      );
      return;
    }

    print('🔌 Connecting WebSocket...');

    // Force WebSocket connection with detailed logging
    try {
      await _webSocketService.connect();
      print('✅ WebSocket connection attempt completed');

      // Test connection after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        print('🧪 Testing WebSocket connection...');
        _webSocketService.testConnection();
      });
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
    }

    print('📍 Getting current location...');
    _getCurrentLocation();
    print('👤 Initializing driver status...');
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.initializeDriverStatus();
    print('🚗 Checking active rides...');
    _checkActiveRides();
    print('💰 Fetching earnings summary...');
    _fetchEarningsSummary();
    print('⏰ Starting ride checking timer...');
    _startRideChecking();
    print('✅ All services initialized');
    print('=== HOME SCREEN READY ===\n');
  }

  void _startRideChecking() {
    // Setup WebSocket ride request listener
    _webSocketService.onRideRequest = (rideData) {
      print('📨 Received ride request via WebSocket: $rideData');
      final driverProvider = Provider.of<DriverProvider>(
        context,
        listen: false,
      );
      if (driverProvider.isOnline && !_hasActiveRequest && mounted) {
        setState(() {
          _nearbyRides = [rideData];
          _currentRideIndex = 0;
          _hasActiveRequest = true;
        });
      }
    };

    // Check nearby rides every 15 seconds (fallback for missed WebSocket messages)
    _rideCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      final driverProvider = Provider.of<DriverProvider>(
        context,
        listen: false,
      );
      if (driverProvider.isOnline && !_hasActiveRequest) {
        _checkNearbyRides();
      }
    });

    // Location update timer removed - will be added back later

    _sessionCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isExpired = await authProvider.isSessionExpired();
      if (isExpired) {
        timer.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RiderSignupSelectionScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _checkNearbyRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.getNearbyRides(token);
      if (result['success'] == true) {
        final rideRequests = List<Map<String, dynamic>>.from(result['data']);
        final transformedRides = rideRequests.map((request) {
          final ride = request['Ride'] ?? {};
          return {
            'ID': ride['ID'],
            'Price': ride['Price']?.toString() ?? '0',
            'PickupAddress': ride['PickupAddress'] ?? 'Unknown pickup',
            'DestAddress': ride['DestAddress'] ?? 'Unknown destination',
            'Note': ride['Note'] ?? '',
            'PaymentMethod': ride['PaymentMethod'] ?? 'in_car',
            'Passenger': ride['Passenger'] ?? {},
            'Status': ride['Status'] ?? 'requested',
          };
        }).toList();

        if (transformedRides.isNotEmpty && !_hasActiveRequest && mounted) {
          setState(() {
            _nearbyRides = transformedRides;
            _currentRideIndex = 0;
            _hasActiveRequest = true;
          });
        }
      }
    }
  }

  // _updateDriverLocation method removed - will be added back later

  Future<void> _acceptRide() async {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length)
      return;

    final ride = _nearbyRides[_currentRideIndex];
    final rideId = ride['ID'];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.acceptRide(token, rideId);
      print('ACCEPT RIDE RESPONSE: $result');
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _hasActiveRequest = false;
            _nearbyRides.clear();
          });
        }
        _showRideAcceptedSheet(ride, result['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to accept ride')),
        );
      }
    }
  }

  Future<void> _declineRide() async {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length)
      return;

    final ride = _nearbyRides[_currentRideIndex];
    final rideId = ride['ID'];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.rejectRide(token, rideId);
      print('REJECT RIDE RESPONSE: $result');
      if (result['success'] == true) {
        print('Ride rejected successfully');
      } else {
        print('Failed to reject ride: ${result['message']}');
      }
    }

    if (mounted) {
      setState(() {
        _currentRideIndex++;
        if (_currentRideIndex >= _nearbyRides.length) {
          _hasActiveRequest = false;
          _nearbyRides.clear();
          _currentRideIndex = 0;
        }
      });
    }
  }

  String _calculateETA(Map<String, dynamic> ride) {
    return '5 min';
  }

  String _formatPaymentMethod(String? method) {
    switch (method) {
      case 'in_car':
        return 'Pay in car';
      case 'wallet':
        return 'Pay with wallet';
      case 'card':
        return 'Pay with card';
      case null:
        return 'Pay in car';
      default:
        return method;
    }
  }

  Future<void> _updateDriverStatus(bool online) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    bool success;

    if (online) {
      success = await driverProvider.setOnline();
    } else {
      success = await driverProvider.setOffline();
    }

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status')));
    }
  }

  void _getCurrentLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      if (_activeRide == null) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: themeManager.getBackgroundColor(context),
      drawer: _buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: themeManager.getCardColor(context),
        selectedItemColor: Color(ConstColors.mainColor),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Image.asset(
                  ConstImages.requests,
                  width: 24.w,
                  height: 24.h,
                  color: _currentIndex == 1
                      ? Color(ConstColors.mainColor)
                      : Colors.grey,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              ConstImages.wallet,
              width: 24.w,
              height: 24.h,
              color: _currentIndex == 2
                  ? Color(ConstColors.mainColor)
                  : Colors.grey,
            ),
            label: 'Earnings',
          ),
        ],
      ),
      body: _currentIndex == 1
          ? ActivitiesScreen()
          : _currentIndex == 2
          ? WalletScreen()
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    RideTrackingService.setMapController(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: _activeRide == null,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _mapMarkers,
                  polylines: _mapPolylines,
                ),
                // Center location pin
                // Center(
                //   child: Icon(
                //     Icons.location_on,
                //     color: Color(ConstColors.mainColor),
                //     size: 40.sp,
                //   ),
                // ),
                // Online/Offline Toggle
                Positioned(
                  top: 80.h,
                  left: 109.w,
                  child: Consumer<DriverProvider>(
                    builder: (context, driverProvider, child) {
                      return Container(
                        width: 175.w,
                        height: 38.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: driverProvider.isLoading
                                    ? null
                                    : () => _updateDriverStatus(true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: driverProvider.isOnline
                                        ? Color(ConstColors.mainColor)
                                        : Color(0xFFB1B1B1).withOpacity(0.3),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15.r),
                                      bottomLeft: Radius.circular(15.r),
                                    ),
                                  ),
                                  child: Center(
                                    child: driverProvider.isLoading
                                        ? SizedBox(
                                            width: 12.w,
                                            height: 12.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Online',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: driverProvider.isLoading
                                    ? null
                                    : () => _updateDriverStatus(false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !driverProvider.isOnline
                                        ? Colors.red
                                        : Color(0xFFB1B1B1).withOpacity(0.3),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(15.r),
                                      bottomRight: Radius.circular(15.r),
                                    ),
                                  ),
                                  child: Center(
                                    child: driverProvider.isLoading
                                        ? SizedBox(
                                            width: 12.w,
                                            height: 12.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Offline',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Drawer button
                Positioned(
                  top: 66.h,
                  left: 20.w,
                  child: GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Icon(Icons.menu, size: 24.sp),
                    ),
                  ),
                ),
                // My Location button
                Positioned(
                  top: 66.h,
                  right: 20.w,
                  child: GestureDetector(
                    onTap: _getCurrentLocation,
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Icon(Icons.my_location, size: 24.sp),
                    ),
                  ),
                ),
                // Bottom sheet
                Positioned(
                  bottom: _isBottomSheetVisible ? 0 : -294.h,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 344.h,
                    width: 393.w,
                    decoration: BoxDecoration(
                      color: themeManager.getCardColor(context),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBottomSheetVisible = !_isBottomSheetVisible;
                              });
                            },
                            child: SizedBox(
                              height: 50.h,
                              child: Column(
                                children: [
                                  SizedBox(height: 11.75.h),
                                  Container(
                                    width: 69.w,
                                    height: 5.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(
                                        2.5.r,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 353.w,
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            decoration: BoxDecoration(
                              color: Color(0xFFB1B1B1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 35.w,
                                  height: 35.h,
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(500.r),
                                  ),
                                  child: Image.asset(
                                    'assets/images/Gift1.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Refer and earn',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                          height: 1.0,
                                          letterSpacing: -0.41,
                                          color: themeManager.getTextColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Refer a friend to earn and win up to #4000',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.sp,
                                          height: 1.0,
                                          letterSpacing: -0.41,
                                          color: themeManager.getTextColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildEarningsSection('Today\'s earning', '₦${_earningsData['total_earnings']}'),
                          Divider(color: Color(0xFFE0E0E0), thickness: 1),
                          _buildEarningsSection('Today\'s rides', '${_earningsData['total_rides']}'),
                          Divider(color: Color(0xFFE0E0E0), thickness: 1),
                          _buildEarningsSection('Total ride completed', '${_earningsData['total_rides_completed']}'),
                        ],
                      ),
                    ),
                  ),
                ),
                // Ride info widget
                if (_activeRide != null && _currentETA.isNotEmpty)
                  RideInfoWidget(
                    eta: _currentETA,
                    location: _currentLocationName,
                    rideStatus: _activeRide!['Status'] ?? 'accepted',
                  ),
                // Floating button to reopen ride sheet when dismissed
                if (_activeRide != null && !_isRideSheetVisible)
                  Positioned(
                    bottom: 120.h,
                    right: 20.w,
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.r),
                          onTap: () => _showRideAcceptedSheet(_activeRide!, {}),
                          child: Center(
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Ride request overlay
                if (_hasActiveRequest && _nearbyRides.isNotEmpty)
                  _buildRideRequestSheet(),
              ],
            ),
    );
  }

  void _checkBothFields() {
    if (fromController.text.isNotEmpty && toController.text.isNotEmpty) {
      _showVehicleSelection();
    }
  }

  void _showVehicleSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 600.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select your vehicle',
                      style: ConstTextStyles.addHomeTitle,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, size: 24.sp),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),
                _buildVehicleOption(
                  0,
                  'Regular vehicle',
                  '20 min | 4 passengers',
                  '₦12,000',
                  setModalState,
                ),
                SizedBox(height: 15.h),
                _buildVehicleOption(
                  1,
                  'Fancy vehicle',
                  '20 min | 4 passengers',
                  '₦12,000',
                  setModalState,
                ),
                SizedBox(height: 15.h),
                _buildVehicleOption(
                  2,
                  'VIP',
                  '20 min | 4 passengers',
                  '₦12,000',
                  setModalState,
                ),
                SizedBox(height: 30.h),
                Text('Delivery service', style: ConstTextStyles.deliveryTitle),
                SizedBox(height: 20.h),
                _buildDeliveryOption(
                  0,
                  'Bicycle',
                  '20 min',
                  '₦12,000',
                  ConstImages.bike,
                  setModalState,
                ),
                SizedBox(height: 15.h),
                _buildDeliveryOption(
                  1,
                  'Vehicle',
                  '20 min',
                  '₦12,000',
                  ConstImages.car,
                  setModalState,
                ),
                SizedBox(height: 15.h),
                _buildDeliveryOption(
                  2,
                  'Motor bike',
                  '20 min',
                  '₦12,000',
                  ConstImages.car,
                  setModalState,
                ),
                SizedBox(height: 30.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: (selectedVehicle != null || selectedDelivery != null)
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: GestureDetector(
                    onTap: (selectedVehicle != null || selectedDelivery != null)
                        ? () {
                            Navigator.pop(context);
                            _showBookingDetails();
                          }
                        : null,
                    child: Center(
                      child: Text(
                        'Select vehicle',
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
      ),
    );
  }

  Widget _buildVehicleOption(
    int index,
    String title,
    String subtitle,
    String price,
    StateSetter setModalState,
  ) {
    final isSelected = selectedVehicle == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = index;
          selectedDelivery = null;
        });
        setModalState(() {});
      },
      child: Container(
        width: 353.w,
        height: 65.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Color(ConstColors.mainColor)
                : Colors.grey.shade300,
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Image.asset(ConstImages.car, width: 55.w, height: 26.h),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: ConstTextStyles.vehicleTitle.copyWith(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: ConstTextStyles.vehicleSubtitle.copyWith(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: ConstTextStyles.vehicleTitle.copyWith(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(
    int index,
    String title,
    String subtitle,
    String price,
    String imagePath,
    StateSetter setModalState,
  ) {
    final isSelected = selectedDelivery == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDelivery = index;
          selectedVehicle = null;
        });
        setModalState(() {});
      },
      child: Container(
        width: 353.w,
        height: 65.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Color(ConstColors.mainColor)
                : Colors.grey.shade300,
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 55.w, height: 26.h),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: ConstTextStyles.vehicleTitle.copyWith(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: ConstTextStyles.vehicleSubtitle.copyWith(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: ConstTextStyles.vehicleTitle.copyWith(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails() {
    final selectedOption = selectedVehicle != null
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBookingState) => Container(
          height: 400.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
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
              GestureDetector(
                onTap: () => _showAddNoteSheet(),
                child: Column(
                  children: [
                    Icon(Icons.message, size: 25.67.w),
                    SizedBox(height: 4.67.h),
                    Text(
                      'Add note',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                        letterSpacing: -0.41,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Image.asset(
                    selectedVehicle != null
                        ? ConstImages.car
                        : ConstImages.bike,
                    width: 55.w,
                    height: 26.h,
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedOption,
                          style: ConstTextStyles.vehicleTitle,
                        ),
                        Text(
                          '4 passengers',
                          style: ConstTextStyles.vehicleSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₦12,000', style: ConstTextStyles.vehicleTitle),
                      Text(
                        'Fixed',
                        style: ConstTextStyles.fixedPrice.copyWith(
                          color: Color(ConstColors.recentLocationColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showVehicleSelection();
                    },
                    child: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => _showPaymentMethods(),
                child: Row(
                  children: [
                    Image.asset(ConstImages.wallet, width: 24.w, height: 24.h),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        selectedPaymentMethod,
                        style: ConstTextStyles.vehicleTitle,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16.sp),
                  ],
                ),
              ),
              Spacer(),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showPrebookSheet();
                    },
                    child: Container(
                      width: 170.w,
                      height: 47.h,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(ConstColors.mainColor)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Book Later',
                          style: TextStyle(
                            color: Color(ConstColors.mainColor),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showBookingRequestSheet();
                    },
                    child: Container(
                      width: 170.w,
                      height: 47.h,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Book Now',
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
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose payment method',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildPaymentOption('Pay with wallet'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('Pay with card'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('pay4me'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('Pay in car'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Expanded(child: Text(method, style: ConstTextStyles.vehicleTitle)),
            if (isSelected) Icon(Icons.check, color: Colors.green, size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setNoteState) => Container(
          height: 300.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
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
              Text(
                'Add note',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 350.w,
                height: 111.h,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Color(0xFFB1B1B1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: null,
                  expands: true,
                  onChanged: (value) {
                    setNoteState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your note here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Spacer(),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: noteController.text.isNotEmpty
                      ? Color(ConstColors.mainColor)
                      : Color(ConstColors.fieldColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: noteController.text.isNotEmpty
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  child: Center(
                    child: Text(
                      'Submit',
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
    );
  }

  Widget _buildDrawer() {
    final themeManager = Provider.of<ThemeManager>(context);
    return Drawer(
      backgroundColor: themeManager.getCardColor(context),
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Image.asset(ConstImages.avatar, width: 60.w, height: 60.h),
                SizedBox(width: 15.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: ConstTextStyles.drawerName.copyWith(
                        color: themeManager.getTextColor(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'My Account',
                        style: ConstTextStyles.drawerAccount.copyWith(
                          color: themeManager.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Divider(thickness: 1, color: Colors.grey.shade300),
          _buildDrawerItem(
            'Wallet',
            ConstImages.wallet,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletScreen()),
              );
            },
          ),
          _buildDrawerItem(
            'Referral',
            ConstImages.referral,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReferralScreen()),
              );
            },
          ),
          _buildDrawerItem(
            'Analytics',
            ConstImages.activities,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            'Contact Us',
            ConstImages.phoneCall,
            onTap: _showContactBottomSheet,
          ),
          _buildDrawerItem('FAQ', ConstImages.faq),
          _buildDrawerItem('About', ConstImages.about),
          Consumer<ThemeManager>(
            builder: (context, themeManager, child) {
              return SwitchListTile(
                title: Text(
                  themeManager.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  style: ConstTextStyles.drawerItem.copyWith(
                    color: themeManager.getTextColor(context),
                  ),
                ),
                value: themeManager.isDarkMode,
                activeThumbColor: Color(ConstColors.mainColor),
                onChanged: (value) {
                  themeManager.toggleTheme();
                },
                secondary: Icon(
                  themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 24.sp,
                  color: themeManager.getTextColor(context),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrebookSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPrebookState) => Container(
          height: 450.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prebook a vehicle',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Select time and date',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                ListTile(
                  leading: Image.asset(
                    ConstImages.activities,
                    width: 24.w,
                    height: 24.h,
                  ),
                  title: Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Color(0xFFB1B1B1),
                    ),
                  ),
                  subtitle: Text(
                    '${_getWeekday(selectedDate.weekday)} ${_getMonth(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                    style: ConstTextStyles.vehicleTitle,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null && picked != selectedDate) {
                      setPrebookState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),
                ListTile(
                  leading: Image.asset(
                    'assets/images/time.png',
                    width: 24.w,
                    height: 24.h,
                  ),
                  title: Text(
                    'Time',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Color(0xFFB1B1B1),
                    ),
                  ),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: ConstTextStyles.vehicleTitle,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null && picked != selectedTime) {
                      setPrebookState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
                SizedBox(height: 30.h),
                Column(
                  children: [
                    Container(
                      width: 353.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(ConstColors.mainColor)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setPrebookState(() {
                            selectedDate = DateTime.now();
                            selectedTime = TimeOfDay.now();
                          });
                        },
                        child: Center(
                          child: Text(
                            'Reset to now',
                            style: TextStyle(
                              color: Color(ConstColors.mainColor),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: 353.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showTripScheduledSheet();
                        },
                        child: Center(
                          child: Text(
                            'Set pick date and time',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _showBookingRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 380.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Text(
                'Booking request successful',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'You\'ll receive a push notification when your driver is assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Pick Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Nsukka, Enugu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Ikeja, Lagos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showBookSuccessfulSheet();
                  },
                  child: Center(
                    child: Text(
                      'View Trip',
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
    );
  }

  void _showBookSuccessfulSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
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
            Text(
              'Book Successful',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'We are searching for available nearby driver',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            SizedBox(
              width: 353.w,
              height: 10.h,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(ConstColors.mainColor),
                ),
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showTripDetailsSheet();
                },
                child: Center(
                  child: Text(
                    'Trip Details',
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
    );
  }

  void _showTripDetailsSheet() {
    final selectedOption = selectedVehicle != null
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: #12345',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Pick Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Nsukka, Enugu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Ikeja, Lagos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'November 28, 2025 at 03:45 pm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedPaymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedOption,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦12,000',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: 328.w,
                height: 50.h,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              'Modify Trip',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 30.h,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              'Chat Driver',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripScheduledSheet() {
    final selectedOption = selectedVehicle != null
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 500.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trip scheduled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Pick Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Nsukka, Enugu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Ikeja, Lagos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'November 28, 2025 at 03:45 pm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedPaymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedOption,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦12,000',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showEditPrebookingSheet();
                  },
                  child: Center(
                    child: Text(
                      'Edit pre booking',
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
    );
  }

  void _showEditPrebookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit pre booking',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              _buildEditField('PICK UP', 'Nsukka, Enugu'),
              SizedBox(height: 15.h),
              _buildEditField('DESTINATION', 'Ikeja, Lagos'),
              SizedBox(height: 15.h),
              _buildEditField('WHEN', 'November 28, 2025 at 03:45 pm'),
              SizedBox(height: 15.h),
              _buildEditField('PAYMENT METHOD', selectedPaymentMethod),
              SizedBox(height: 15.h),
              _buildEditField(
                'VEHICLE',
                selectedVehicle != null
                    ? [
                        'Regular vehicle',
                        'Fancy vehicle',
                        'VIP',
                      ][selectedVehicle!]
                    : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!],
              ),
              SizedBox(height: 40.h),
              Column(
                children: [
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTripCanceledSheet();
                      },
                      child: Center(
                        child: Text(
                          'Cancel prebooking',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(
                          'Save prebooking',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: Color(0xFFB1B1B1).withOpacity(0.12),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTripCanceledSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setCancelState) => Container(
          height: 450.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trip Canceled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Help us improve by sharing why you are canceling',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              _buildCancelReason(
                0,
                'I am taking alternative transport',
                setCancelState,
              ),
              SizedBox(height: 10.h),
              _buildCancelReason(
                1,
                'It is taking too long to get a driver',
                setCancelState,
              ),
              SizedBox(height: 10.h),
              _buildCancelReason(
                2,
                'I have to attend to something',
                setCancelState,
              ),
              SizedBox(height: 10.h),
              _buildCancelReason(3, 'Others', setCancelState),
              Spacer(),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: selectedCancelReason != null
                      ? Color(ConstColors.mainColor)
                      : Color(ConstColors.fieldColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: selectedCancelReason != null
                      ? () {
                          Navigator.pop(context);
                          _showFeedbackSuccessSheet();
                        }
                      : null,
                  child: Center(
                    child: Text(
                      'Submit',
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
    );
  }

  Widget _buildCancelReason(
    int index,
    String reason,
    StateSetter setCancelState,
  ) {
    final isSelected = selectedCancelReason == index;
    return GestureDetector(
      onTap: () {
        setCancelState(() {
          selectedCancelReason = index;
        });
      },
      child: Container(
        width: 353.w,
        height: 40.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.white,
          border: Border.all(color: Color(ConstColors.mainColor)),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Text(
            reason,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 400.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 30.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Container(
              width: 266.w,
              height: 212.h,
              margin: EdgeInsets.only(top: 30.h, left: 62.w),
              child: Image.asset(
                'assets/images/Feedback_suucess.png',
                fit: BoxFit.contain,
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    'GO HOME',
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
    );
  }

  Future<void> _fetchEarningsSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      final result = await ApiService.getEarningsSummary(token);
      if (result['success'] == true) {
        final summary = result['data']['summary'] ?? {};
        if (mounted) {
          setState(() {
            _earningsData = {
              'total_earnings': summary['total_earnings'] ?? 0,
              'total_rides': summary['total_rides'] ?? 0,
              'total_rides_completed': summary['total_rides'] ?? 0,
            };
          });
        }
      }
    }
  }

  Widget _buildEarningsSection(String title, String value) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    height: 1.0,
                    letterSpacing: -0.41,
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 24.sp,
                    height: 1.0,
                    letterSpacing: -0.41,
                    color: themeManager.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    String title,
    String iconPath, {
    VoidCallback? onTap,
  }) {
    final themeManager = Provider.of<ThemeManager>(context);
    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 24.w,
        height: 24.h,
        color: themeManager.getTextColor(context),
      ),
      title: Text(
        title,
        style: ConstTextStyles.drawerItem.copyWith(
          color: themeManager.getTextColor(context),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildRequestsScreen() {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            SizedBox(height: 40.h),
            _buildEarningsSection('Today\'s earning', '₦2,500'),
            Divider(color: Color(0xFFE0E0E0), thickness: 1),
            _buildEarningsSection('Today\'s rides', '12'),
            Divider(color: Color(0xFFE0E0E0), thickness: 1),
            _buildEarningsSection('Total ride completed', '245'),
            SizedBox(height: 30.h),
            _buildOrderItem(
              '10:30 AM',
              'Nov 28, 2024',
              '#12345',
              'Destination',
              'Ikeja, Lagos',
            ),
            SizedBox(height: 15.h),
            _buildOrderItem(
              '2:15 PM',
              'Nov 27, 2024',
              '#12346',
              'Destination',
              'Victoria Island',
            ),
            SizedBox(height: 15.h),
            _buildOrderItem(
              '8:45 AM',
              'Nov 27, 2024',
              '#12347',
              'Destination',
              'Lekki Phase 1',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(
    String time,
    String date,
    String tripId,
    String destinationLabel,
    String location,
  ) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: themeManager.getCardColor(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tripId,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  destinationLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: themeManager.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestSheet() {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length) {
      return SizedBox.shrink();
    }

    final ride = _nearbyRides[_currentRideIndex];
    final passenger = ride['Passenger'] ?? {};
    final eta = _calculateETA(ride);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: 393.w,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            eta.replaceAll(' min', ''),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'min',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        width: 70.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 15.w),
                Text(
                  'New Order',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
            Text(
              '₦${ride['Price']}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 36.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Pickup: ${ride['PickupAddress'] ?? 'Unknown location'}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Destination: ${ride['DestAddress'] ?? 'Unknown destination'}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 15.h),
            if (ride['Note'] != null && ride['Note'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note: ${ride['Note']}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp),
                  ),
                  SizedBox(height: 15.h),
                ],
              ),
            Container(
              width: 353.w,
              height: 42.h,
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(width: 0.6, color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Image.asset(ConstImages.wallet, width: 20.w, height: 20.h),
                  SizedBox(width: 8.w),
                  Text(
                    _formatPaymentMethod(ride['PaymentMethod'] ?? 'in_car'),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _declineRide,
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: _acceptRide,
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkActiveRides() async {
    print('=== CHECKING ACTIVE RIDES ===');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      print('Token found, calling getActiveRides API');
      final result = await ApiService.getActiveRides(token);
      print('API Result: $result');

      if (result['success'] == true) {
        final rides = result['data']['rides'] as List;
        print('Number of active rides: ${rides.length}');

        if (rides.isNotEmpty) {
          final activeRide = rides.first;
          print('Active ride found: $activeRide');
          print('Ride Status: ${activeRide['Status']}');
          print('Ride ID: ${activeRide['ID']}');
          _showRideAcceptedSheet(activeRide, {});
        } else {
          print('No active rides found');
        }
      } else {
        print('Failed to get active rides: ${result['message']}');
      }
    } else {
      print('No auth token found');
    }
    print('=== END CHECKING ACTIVE RIDES ===\n');
  }

  void _showRideAcceptedSheet(
    Map<String, dynamic> ride,
    Map<String, dynamic> acceptedData,
  ) {
    if (mounted) {
      setState(() {
        _activeRide = ride;
        _isRideSheetVisible = true;
      });
    }

    // Start ride tracking only if not already started
    if (_mapMarkers.isEmpty) {
      RideTrackingService.startRideTracking(
        ride: ride,
        onUpdate: (markers, polylines) {
          if (mounted) {
            setState(() {
              _mapMarkers = markers;
              _mapPolylines = polylines;
            });
          }
        },
        onTimeUpdate: (eta, location) {
          if (mounted) {
            setState(() {
              _currentETA = eta;
              _currentLocationName = location;
            });
          }
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // Allow dismissal
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _RideAcceptedSheet(
        ride: ride,
        acceptedData: acceptedData,
        onRideStatusChanged: _onRideStatusChanged,
      ),
    ).whenComplete(() {
      // Update visibility when sheet is dismissed
      if (mounted) {
        setState(() {
          _isRideSheetVisible = false;
        });
      }
    });
  }

  void _onRideStatusChanged(Map<String, dynamic> updatedRide) {
    print('=== RIDE STATUS CHANGED ===');
    print('Updated Ride Status: ${updatedRide['Status']}');

    if (mounted) {
      setState(() {
        _activeRide = updatedRide;
      });
    }

    // Update the tracking service with new ride status
    RideTrackingService.updateRideStatus(updatedRide);

    if (updatedRide['Status'] == 'completed' ||
        updatedRide['Status'] == 'cancelled') {
      // Stop tracking when ride is completed or cancelled
      print('Stopping tracking for completed/cancelled ride');
      RideTrackingService.stopTracking();

      // Force clear the map display
      if (mounted) {
        setState(() {
          _activeRide = null;
          _isRideSheetVisible = true; // Reset visibility
          _mapMarkers = {}; // Clear markers
          _mapPolylines = {}; // Clear polylines
          _currentETA = '';
          _currentLocationName = '';
        });
      }

      // Close any open modal sheets
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    print('=== RIDE STATUS CHANGE HANDLED ===\n');
  }
}

class _RideAcceptedSheet extends StatefulWidget {
  final Map<String, dynamic> ride;
  final Map<String, dynamic> acceptedData;
  final Function(Map<String, dynamic>) onRideStatusChanged;

  const _RideAcceptedSheet({
    required this.ride,
    required this.acceptedData,
    required this.onRideStatusChanged,
  });

  @override
  State<_RideAcceptedSheet> createState() => _RideAcceptedSheetState();
}

class _RideAcceptedSheetState extends State<_RideAcceptedSheet> {
  double _sliderValue = 0.0;
  bool _isArrived = false;
  bool _isStarted = false;
  final bool _isCompleted = false;
  bool _showGreenSlider = false;
  String get _rideStatus => widget.ride['Status'] ?? 'accepted';

  @override
  Widget build(BuildContext context) {
    final passenger = widget.ride['Passenger'] ?? {};
    final tip = widget.acceptedData['tip'] ?? 0;
    final waitFee = widget.acceptedData['wait_fee'] ?? 0;

    return Container(
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
          Text(
            '₦${widget.ride['Price']}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 36.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Extra(tip): ₦$tip',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: 1.w, height: 20.h, color: Colors.grey.shade300),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Wait: ₦$waitFee',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pickup: ${widget.ride['PickupAddress'] ?? 'Unknown location'}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Destination: ${widget.ride['DestAddress'] ?? 'Unknown destination'}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 15.h),
          Container(
            width: 353.w,
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(width: 0.6, color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  _formatPaymentMethod(widget.ride['PaymentMethod']),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Chat ${passenger['first_name'] ?? 'Passenger'}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          height: 22 / 18,
                          letterSpacing: -0.41,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1.w, height: 30.h, color: Colors.grey.shade300),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Call ${passenger['first_name'] ?? 'Passenger'}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          height: 22 / 18,
                          letterSpacing: -0.41,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
          if (_rideStatus == 'completed')
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryCompletedScreen(
                        ride: widget.ride,
                        acceptedData: widget.acceptedData,
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else if (_rideStatus == 'started')
            Column(
              children: [
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 4.w + (_sliderValue * (353.w - 40.w)),
                        top: 8.h,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _sliderValue =
                                  ((details.localPosition.dx - 4.w) /
                                          (353.w - 40.w))
                                      .clamp(0.0, 1.0);
                            });
                          },
                          onPanEnd: (details) {
                            if (_sliderValue >= 0.8) {
                              _completeRide();
                            } else {
                              setState(() {
                                _sliderValue = 0.0;
                              });
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 10.w),
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16.sp,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _isCompleted ? 'Trip ended' : 'Swipe to end trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Emergency Situation?',
                  style: TextStyle(
                    color: Color(ConstColors.mainColor),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _showGreenSlider
                        ? Colors.green
                        : (_rideStatus == 'arrived' && !_showGreenSlider
                              ? Color(0xFFB1B1B1)
                              : Color(0xFFB1B1B1)),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 4.w + (_sliderValue * (353.w - 40.w)),
                        top: 8.h,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _sliderValue =
                                  ((details.localPosition.dx - 4.w) /
                                          (353.w - 40.w))
                                      .clamp(0.0, 1.0);
                            });
                          },
                          onPanEnd: (details) {
                            if (_sliderValue >= 0.8) {
                              if (_rideStatus == 'arrived') {
                                _startRide();
                              } else {
                                _markAsArrived();
                              }
                            } else {
                              setState(() {
                                _sliderValue = 0.0;
                              });
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(left: 10.w, right: 10.w),
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16.sp,
                              color: _showGreenSlider
                                  ? Colors.green
                                  : Color(0xFFB1B1B1),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _rideStatus == 'arrived'
                              ? (_isStarted ? 'Ride started' : 'Swipe to start')
                              : (_isArrived
                                    ? 'Arrived!'
                                    : 'Slide to mark as arrived'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_rideStatus != 'started' && _rideStatus != 'completed')
                  Column(
                    children: [
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: _showCancelDialog,
                        child: Container(
                          width: 353.w,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          padding: EdgeInsets.all(10.w),
                          child: Center(
                            child: Text(
                              'Cancel ride',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Future<void> _markAsArrived() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.arriveRide(token, widget.ride['ID']);
      print('ARRIVE RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isArrived = true;
          _showGreenSlider = true;
        });

        // Update ride status and notify parent
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'arrived';
        widget.onRideStatusChanged(updatedRide);

        // Show arrived confirmation for 2 seconds, then switch to start ride
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGreenSlider = false; // Switch to start ride slider
              _sliderValue = 0.0; // Reset slider position
            });
          }
        });
      } else {
        // Reset slider position
        setState(() {
          _sliderValue = 0.0;
        });

        // Show custom popup dialog
        _showDistanceErrorDialog(context);
      }
    }
  }

  Future<void> _startRide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.startRide(token, widget.ride['ID']);
      print('START RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isStarted = true;
        });

        // Update ride status and notify parent
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'started';
        widget.onRideStatusChanged(updatedRide);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to start ride')),
        );
      }
    }
  }

  Future<void> _completeRide() async {
    print('=== COMPLETE RIDE CALLED ===');
    print('Ride ID: ${widget.ride['ID']}');
    print('Ride Status: ${widget.ride['Status']}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print('Auth Token: ${token != null ? 'Present' : 'Missing'}');

    if (token != null) {
      print('Calling ApiService.completeRide...');
      final result = await ApiService.completeRide(token, widget.ride['ID']);
      print('COMPLETE RIDE API RESPONSE: $result');

      if (result['success'] == true) {
        print('Ride completed successfully');

        // Update ride status and notify parent
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'completed';
        widget.onRideStatusChanged(updatedRide);

        // Close current sheet and show completed sheet
        Navigator.of(context).pop();
        _showCompletedSheet(context, updatedRide);

        print('State updated and callback called');
      } else {
        print('Failed to complete ride: ${result['message']}');
        setState(() {
          _sliderValue = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to complete ride'),
          ),
        );
      }
    } else {
      print('No auth token found');
    }
    print('=== END COMPLETE RIDE ===\n');
  }

  void _showCompletedSheet(BuildContext context, Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
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
            Text(
              'Trip Completed',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '₦${ride['Price']}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 36.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            SizedBox(height: 30.h),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryCompletedScreen(
                        ride: ride,
                        acceptedData: {},
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for cancellation:'),
            SizedBox(height: 10.h),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter cancellation reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _cancelRide(reasonController.text),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDistanceErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 353.w,
          height: 150.h,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Text(
                  'You are still very far to the pickup location to swipe to arrive. You have to be 1km near the pickup before you can swipe to arrive.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 282.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Center(
                    child: Text(
                      'Ok',
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }

  Future<void> _cancelRide(String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a cancellation reason')),
      );
      return;
    }

    Navigator.pop(context); // Close dialog

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.cancelRideWithReason(
        token,
        widget.ride['ID'],
        reason,
      );
      if (result['success'] == true) {
        // Update ride status and notify parent - this will handle closing the sheet
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'cancelled';
        widget.onRideStatusChanged(updatedRide);
        // Don't call Navigator.pop here - the parent will handle it
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ride cancelled successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to cancel ride')),
        );
      }
    }
  }

  String _formatPaymentMethod(String? method) {
    switch (method) {
      case 'in_car':
        return 'Pay in car';
      case 'wallet':
        return 'Pay with wallet';
      case 'card':
        return 'Pay with card';
      case null:
        return 'Pay in car';
      default:
        return method;
    }
  }
}
