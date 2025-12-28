import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/services/ride_tracking_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam_rider/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/communication/presentation/screens/chat_screen.dart';
import 'package:muvam_rider/features/communication/presentation/widgets/notificationchat.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/wallet_screen.dart';
import 'package:muvam_rider/features/home/data/provider/driver_provider.dart';
import 'package:muvam_rider/features/home/presentation/widgets/ride_info_widget.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam_rider/features/referral/presentation/screens/referral_screen.dart';
import 'package:muvam_rider/features/support/presentation/screens/about_us_screen.dart';
import 'package:muvam_rider/features/support/presentation/screens/faq_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_completed_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

//FOR DRIVER
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
  final int _selectedPeriodIndex = 0;
  final int _selectedTabIndex = 0;
  bool _isRideSheetVisible = true;
  List<String> recentLocations = [
    'Nsukka, Ogige',
    'Holy ghost Enugu',
    'Abakpa, Enugu',
  ];
  // final WebSocketService _webSocketService = WebSocketService();

  late final WebSocketService _webSocketService;

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
  final CallService _callService = CallService();
  DateTime? _lastBackPress;
  final String _driverArrivalTime =
      '5'; // Default driver arrival time in minutes

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
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet
                final Uri phoneUri = Uri(scheme: 'tel', path: '07032992768');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  if (mounted) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Could not open phone dialer',
                    );
                  }
                }
              },
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
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet
                // WhatsApp URL with phone number (remove leading 0, add country code)
                final Uri whatsappUri = Uri.parse(
                  'https://wa.me/2347032992768', // Nigeria country code +234
                );
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(
                    whatsappUri,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  if (mounted) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Could not open WhatsApp',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletSummary();
      context.read<RequestProvider>().startAutoRefresh();
    });

    _webSocketService = WebSocketService.instance; // Get singleton instance

    _initializeServices();
  }

  @override
  void dispose() {
    _webSocketService.onRideRequest = null;
    _webSocketService.onRideCompleted = null;
    _webSocketService.disconnect();
    _rideCheckTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _callService.dispose();
    context.read<RequestProvider>().stopAutoRefresh();
    RideTrackingService.stopTracking();
    super.dispose();
  }

  void _initializeServices() async {
    AppLogger.log('=== INITIALIZING HOME SCREEN SERVICES ===');

    // Check session expiration first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isExpired = await authProvider.isSessionExpired();

    if (isExpired) {
      AppLogger.log('🔒 Session expired, redirecting to login...');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RiderSignupSelectionScreen()),
        (route) => false,
      );
      return;
    }

    // Fetch user profile
    AppLogger.log('👤 Fetching user profile...');
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.fetchUserProfile();

    AppLogger.log('🔌 Connecting WebSocket...');
    try {
      await _webSocketService.connect();
      AppLogger.log('✅ WebSocket connection attempt completed');

      Future.delayed(Duration(seconds: 2), () {
        AppLogger.log('🧪 Testing WebSocket connection...');
      });
    } catch (e) {
      AppLogger.log('❌ WebSocket connection failed: $e');
    }

    // CRITICAL: Register chat handler GLOBALLY in HomeScreen
    _webSocketService.onChatMessage = (chatData) {
      AppLogger.log('💬 Global chat handler called in HomeScreen');
      _handleGlobalChatMessage(chatData);
    };

    // NEW: Send "Hello" message to open WebSocket channel
    if (_activeRide != null) {
      AppLogger.log(
        '📤 Sending initialization message to open WebSocket channel...',
      );
      Future.delayed(Duration(seconds: 3), () {
        if (_webSocketService.isConnected) {
          _webSocketService.sendMessage({
            "type": "chat",
            "data": {"ride_id": _activeRide!['ID'], "message": "Hello"},
          });
          AppLogger.log('✅ Initialization message sent');
        }
      });
    }

    // Setup WebSocket ride completion handler
    _webSocketService.onRideCompleted = (completionData) {
      AppLogger.log(
        '🎉 Ride completion received via WebSocket: $completionData',
      );
      if (mounted) {
        // Close any open sheets first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Small delay before showing completion sheet
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _showCompletedSheet(context, _activeRide ?? {});
          }
        });

        // Update local state
        final updatedRide = Map<String, dynamic>.from(_activeRide ?? {});
        updatedRide['Status'] = 'completed';
        _onRideStatusChanged(updatedRide);
      }
    };

    AppLogger.log('📍 Getting current location...');
    _getCurrentLocation();

    AppLogger.log('👤 Initializing driver status...');
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.initializeDriverStatus();

    AppLogger.log('🚗 Checking active rides...');
    _checkActiveRides();

    AppLogger.log('💰 Fetching earnings summary...');
    _fetchEarningsSummary();

    AppLogger.log('⏰ Starting ride checking timer...');
    _startRideChecking();

    AppLogger.log('✅ All services initialized');
    AppLogger.log('=== HOME SCREEN READY ===\n');
  }

  // Add this new method to handle global chat messages
  void _handleGlobalChatMessage(Map<String, dynamic> chatData) async {
    try {
      AppLogger.log('📨 Processing global chat message');
      final data = chatData['data'] ?? {};
      final messageText = data['message'] ?? '';
      final senderName = data['sender_name'] ?? 'Unknown User';
      final senderImage = data['sender_image'];
      final senderId = data['sender_id']?.toString() ?? '';
      final rideId = data['ride_id'] ?? 0;
      final timestamp =
          chatData['timestamp'] ?? DateTime.now().toIso8601String();

      AppLogger.log('   Message: "$messageText"');
      AppLogger.log('   From: $senderName (ID: $senderId)');
      AppLogger.log('   Ride: $rideId');

      // Get current user ID to check if this is our own message
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      AppLogger.log('   Current User ID: $currentUserId');
      AppLogger.log('   Sender ID: $senderId');

      // Add message to ChatProvider so it's available when user opens ChatScreen
      if (mounted && rideId > 0) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final message = ChatMessageModel(
          message: messageText,
          timestamp: timestamp,
          rideId: rideId,
          userId: senderId,
        );

        chatProvider.addMessage(rideId, message);
        AppLogger.log('✅ Message added to ChatProvider');

        // Only show notification if the message is NOT from the current user
        if (senderId != currentUserId) {
          AppLogger.log('📢 Showing notification for message from other user');
          // Show notification
          ChatNotificationService.showChatNotification(
            context,
            senderName: senderName,
            message: messageText,
            senderImage: senderImage,
            onTap: () {
              AppLogger.log('🔔 Notification tapped, navigating to chat');

              // Navigate to chat screen
              if (_activeRide != null) {
                final passenger = _activeRide!['Passenger'] ?? {};
                final passengerName =
                    '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
                final passengerImage =
                    passenger['profile_image'] ?? passenger['image'];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      rideId: rideId,
                      driverName: passengerName,
                      driverImage: passengerImage,
                    ),
                  ),
                );
              } else {
                // Fallback if no active ride
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      rideId: rideId,
                      driverName: senderName,
                      driverImage: senderImage,
                    ),
                  ),
                );
              }
            },
          );
        } else {
          AppLogger.log(
            '🔇 Skipping notification - message is from current user',
          );
        }
      }
    } catch (e, stack) {
      AppLogger.log('❌ Error handling global chat message: $e');
      AppLogger.log('Stack: $stack');
    }
  }

  void _startRideChecking() {
    // Setup WebSocket ride request listener
    _webSocketService.onRideRequest = (rideData) {
      AppLogger.log('📨 Received ride request via WebSocket: $rideData');
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

    // Driver location update timer (always when online)
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final driverProvider = Provider.of<DriverProvider>(
        context,
        listen: false,
      );
      if (driverProvider.isOnline) {
        _updateDriverLocationToBackend();
      }
    });

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

  Future<void> _updateDriverLocationToBackend() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        // Use ride-specific location update if in active ride, otherwise general update
        Map<String, dynamic> result;
        if (_activeRide != null) {
          result = await ApiService.updateDriverLocation(
            token,
            _activeRide!['ID'],
            position.latitude,
            position.longitude,
          );
        } else {
          result = await ApiService.updateDriverLocationGeneral(
            token,
            position.latitude,
            position.longitude,
          );
        }

        if (result['success'] == true) {
          AppLogger.log(
            '✅ Driver location updated: ${position.latitude}, ${position.longitude}',
          );
        }
      }
    } catch (e) {
      AppLogger.log('❌ Failed to update driver location: $e');
    }
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
            'StopAddress': ride['StopAddress'] ?? '',
            'Note': ride['Note'] ?? '',
            'PaymentMethod': ride['PaymentMethod'] ?? 'in_car',
            'Passenger': ride['Passenger'] ?? {},
            'Status': ride['Status'] ?? 'requested',
            // CRITICAL: Include location data for markers
            'PickupLocation': ride['PickupLocation'],
            'DestLocation': ride['DestLocation'],
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
    // Extract ride ID from WebSocket data structure
    final rideData = ride['data'] ?? ride;
    final rideId = rideData['RideID'] ?? rideData['ID'] ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.acceptRide(token, rideId);
      AppLogger.log('ACCEPT RIDE RESPONSE: $result');
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _hasActiveRequest = false;
            _nearbyRides.clear();
          });
        }
        // Transform WebSocket data to expected format for ride sheet
        final transformedRide = {
          'ID': rideId,
          'Price': rideData['Price']?.toString() ?? '0',
          'PickupAddress': rideData['PickupAddress'] ?? 'Unknown pickup',
          'DestAddress': rideData['DestAddress'] ?? 'Unknown destination',
          'StopAddress': rideData['StopAddress'] ?? '',
          'Note': rideData['Note'] ?? '',
          'Status': 'accepted',
          'Passenger':
              rideData['Passenger'] ??
              {
                'first_name':
                    rideData['PassengerName']?.split(' ').first ?? 'Unknown',
                'last_name':
                    rideData['PassengerName']?.split(' ').skip(1).join(' ') ??
                    'Passenger',
              },
          'ServiceType': rideData['ServiceType'] ?? 'taxi',
          'VehicleType': rideData['VehicleType'] ?? 'regular',
          // CRITICAL: Include location data for ride tracking
          'PickupLocation': rideData['PickupLocation'],
          'DestLocation': rideData['DestLocation'],
          'PickupAddress': rideData['PickupAddress'] ?? 'Unknown pickup',
          'DestAddress': rideData['DestAddress'] ?? 'Unknown destination',
          // Keep original data structure for tracking service
          'data': rideData,
        };

        AppLogger.log('🔄 TRANSFORMED RIDE DATA:');
        AppLogger.log('   Transformed keys: ${transformedRide.keys.toList()}');
        AppLogger.log(
          '   PickupLocation: ${transformedRide['PickupLocation']}',
        );
        AppLogger.log('   DestLocation: ${transformedRide['DestLocation']}');
        AppLogger.log('   Has data field: ${transformedRide['data'] != null}');

        // CRITICAL DEBUG: Log ALL location-related fields from rideData
        AppLogger.log('🚨 LOCATION DATA DEBUG (from rideData):');
        AppLogger.log('   rideData keys: ${rideData.keys.toList()}');
        AppLogger.log('   PickupLocation: ${rideData['PickupLocation']}');
        AppLogger.log('   DestLocation: ${rideData['DestLocation']}');
        AppLogger.log('   PickupLat: ${rideData['PickupLat']}');
        AppLogger.log('   PickupLng: ${rideData['PickupLng']}');
        AppLogger.log('   DestLat: ${rideData['DestLat']}');
        AppLogger.log('   DestLng: ${rideData['DestLng']}');
        AppLogger.log('   pickup_location: ${rideData['pickup_location']}');
        AppLogger.log('   dest_location: ${rideData['dest_location']}');

        // If location coordinates are missing, geocode the addresses
        if (transformedRide['PickupLocation'] == null ||
            transformedRide['DestLocation'] == null) {
          AppLogger.log(
            '🌍 Location coordinates missing, geocoding addresses...',
          );
          await _geocodeAndShowRide(transformedRide, result['data']);
        } else {
          _showRideAcceptedSheet(transformedRide, result['data']);
        }
      } else {
        CustomFlushbar.showError(
          context: context,
          message: result['message'] ?? 'Failed to accept ride',
        );
      }
    }
  }

  Future<void> _geocodeAndShowRide(
    Map<String, dynamic> ride,
    Map<String, dynamic> acceptedData,
  ) async {
    try {
      final pickupAddress = ride['PickupAddress'] ?? '';
      final destAddress = ride['DestAddress'] ?? '';

      AppLogger.log('📍 Geocoding pickup address: $pickupAddress');
      AppLogger.log('📍 Geocoding dest address: $destAddress');

      // Geocode pickup address
      final pickupUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(pickupAddress)}&key=${UrlConstants.googleMapsApiKey}',
      );

      final pickupResponse = await http.get(pickupUrl);
      final pickupData = json.decode(pickupResponse.body);

      // Geocode destination address
      final destUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(destAddress)}&key=${UrlConstants.googleMapsApiKey}',
      );

      final destResponse = await http.get(destUrl);
      final destData = json.decode(destResponse.body);

      if (pickupData['status'] == 'OK' &&
          pickupData['results'].isNotEmpty &&
          destData['status'] == 'OK' &&
          destData['results'].isNotEmpty) {
        final pickupLat =
            pickupData['results'][0]['geometry']['location']['lat'];
        final pickupLng =
            pickupData['results'][0]['geometry']['location']['lng'];
        final destLat = destData['results'][0]['geometry']['location']['lat'];
        final destLng = destData['results'][0]['geometry']['location']['lng'];

        AppLogger.log('✅ Geocoded pickup: $pickupLat, $pickupLng');
        AppLogger.log('✅ Geocoded dest: $destLat, $destLng');

        // Convert to WKB format (POINT format) for compatibility
        final pickupWKB = 'POINT($pickupLng $pickupLat)';
        final destWKB = 'POINT($destLng $destLat)';

        // Update ride data with geocoded locations
        ride['PickupLocation'] = pickupWKB;
        ride['DestLocation'] = destWKB;

        // Also update the nested data object
        if (ride['data'] != null) {
          ride['data']['PickupLocation'] = pickupWKB;
          ride['data']['DestLocation'] = destWKB;
        }

        AppLogger.log('✅ Updated ride with geocoded locations');
        _showRideAcceptedSheet(ride, acceptedData);
      } else {
        AppLogger.log('❌ Geocoding failed, showing ride without markers');
        AppLogger.log('   Pickup status: ${pickupData['status']}');
        AppLogger.log('   Dest status: ${destData['status']}');
        _showRideAcceptedSheet(ride, acceptedData);
      }
    } catch (e) {
      AppLogger.log('❌ Error geocoding addresses: $e');
      _showRideAcceptedSheet(ride, acceptedData);
    }
  }

  Future<void> _declineRide() async {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length)
      return;

    final ride = _nearbyRides[_currentRideIndex];
    // Extract ride ID from WebSocket data structure
    final rideData = ride['data'] ?? ride;
    final rideId = rideData['RideID'] ?? rideData['ID'] ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.rejectRide(token, rideId);
      AppLogger.log('REJECT RIDE RESPONSE: $result');
      if (result['success'] == true) {
        AppLogger.log('Ride rejected successfully');
      } else {
        AppLogger.log('Failed to reject ride: ${result['message']}');
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
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to update status',
      );
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

  void _centerMapOnActiveRide() {
    if (_activeRide == null || _mapController == null) {
      AppLogger.log(
        '⚠️ Cannot center map: activeRide=${_activeRide != null}, mapController=${_mapController != null}',
      );
      return;
    }

    AppLogger.log('🎯 Attempting to center map on active ride');

    try {
      // If we have markers, use them to center the map
      if (_mapMarkers.isNotEmpty) {
        Marker? pickupMarker;
        try {
          pickupMarker = _mapMarkers.firstWhere(
            (marker) => marker.markerId.value == 'pickup',
          );
        } catch (e) {
          pickupMarker = null;
        }

        if (pickupMarker != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(pickupMarker.position, 14),
          );
          AppLogger.log(
            '✅ Map centered on pickup marker: ${pickupMarker.position}',
          );
          return;
        }

        // Fallback to any available marker
        final anyMarker = _mapMarkers.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(anyMarker.position, 14),
        );
        AppLogger.log(
          '✅ Map centered on available marker: ${anyMarker.position}',
        );
      } else {
        AppLogger.log('⚠️ No markers available for centering');
      }
    } catch (e) {
      AppLogger.log('❌ Error centering map on active ride: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
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
                      // If there's an active ride when map is created, center on it
                      if (_activeRide != null) {
                        _centerMapOnActiveRide();
                      }
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
                    top: 60.h,
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
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
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
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
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
                    top: 50.h,
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
                    top: 50.h,
                    right: 20.w,
                    child: GestureDetector(
                      onTap: () {
                        if (_activeRide != null) {
                          // If there's an active ride, center on it
                          _centerMapOnActiveRide();
                        } else {
                          // Otherwise center on current location
                          _getCurrentLocation();
                        }
                      },
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: Icon(
                          _activeRide != null
                              ? Icons.directions_car
                              : Icons.my_location,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                  // Stop Address Marker (if exists)
                  if (_activeRide != null &&
                      _activeRide!['StopAddress'] != null &&
                      _activeRide!['StopAddress'].toString().isNotEmpty)
                    Positioned(
                      top: 120.h,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildStopMarkerWidget()),
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
                                  _isBottomSheetVisible =
                                      !_isBottomSheetVisible;
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
                                      borderRadius: BorderRadius.circular(
                                        500.r,
                                      ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                            _buildEarningsSection(
                              'Today\'s earning',
                              '₦${_earningsData['total_earnings']}',
                            ),
                            Divider(color: Color(0xFFE0E0E0), thickness: 1),
                            _buildEarningsSection(
                              'Today\'s rides',
                              '${_earningsData['total_rides']}',
                            ),
                            Divider(color: Color(0xFFE0E0E0), thickness: 1),
                            _buildEarningsSection(
                              'Total ride completed',
                              '${_earningsData['total_rides_completed']}',
                            ),
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
                            onTap: () =>
                                _showRideAcceptedSheet(_activeRide!, {}),
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

                  // Full-screen incoming call overlay
                ],
              ),
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
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Drawer(
      backgroundColor: themeManager.getCardColor(context),
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                profileProvider.userProfilePhoto.isNotEmpty
                    ? CircleAvatar(
                        radius: 30.r,
                        backgroundImage: NetworkImage(
                          profileProvider.userProfilePhoto,
                        ),
                      )
                    : Image.asset(
                        ConstImages.avatar,
                        width: 60.w,
                        height: 60.h,
                      ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileProvider.userShortName,
                        style: ConstTextStyles.drawerName.copyWith(
                          color: themeManager.getTextColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
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
          _buildDrawerItem(
            'FAQ',
            ConstImages.faq,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaqScreen()),
              );
            },
          ),
          _buildDrawerItem(
            'About',
            ConstImages.about,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsScreen()),
              );
            },
          ),
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

    // Extract ride data at the beginning of the method
    final ride = _activeRide;

    // Return early if no active ride
    if (ride == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'No active ride found',
      );
      return;
    }

    final passenger = ride['Passenger'] ?? {};
    final passengerFirstName = passenger['first_name'] ?? 'Unknown';
    final passengerLastName = passenger['last_name'] ?? '';
    final passengerName = '$passengerFirstName $passengerLastName'.trim();
    final passengerImage =
        passenger['profile_image'] ?? passenger['image'] ?? '';
    final rideId = ride['ID'];
    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final price = ride['Price']?.toString() ?? '0';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';
    final createdAt = ride['CreatedAt'] ?? ride['created_at'] ?? '';

    // Format date
    String formattedDate = 'Unknown date';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {
        AppLogger.log('Error parsing date: $e');
      }
    }

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
                    'ID: #$rideId',
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
                          pickupAddress,
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
                          destAddress,
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
                  formattedDate,
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
                          _formatPaymentMethod(paymentMethod),
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
                          ride['VehicleType'] ?? selectedOption,
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
                      '₦$price',
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
                              builder: (context) => ChatScreen(
                                rideId: rideId,
                                driverName: passengerName,
                                driverImage: passengerImage.isNotEmpty
                                    ? passengerImage
                                    : null,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              'Chat Passenger',
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

    // Extract ride data
    final ride = _activeRide;

    // Return early if no active ride
    if (ride == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'No scheduled ride found',
      );
      return;
    }

    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final price = ride['Price']?.toString() ?? '0';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';
    final scheduledAt = ride['ScheduledAt'] ?? ride['scheduled_at'] ?? '';

    // Format scheduled date
    String formattedDate = 'Unknown date';
    if (scheduledAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(scheduledAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {
        AppLogger.log('Error parsing scheduled date: $e');
      }
    }

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
                          pickupAddress,
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
                          destAddress,
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
                  formattedDate,
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
                          _formatPaymentMethod(paymentMethod),
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
                          ride['VehicleType'] ?? selectedOption,
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
                      '₦$price',
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
    // Extract ride data
    final ride = _activeRide;

    // Return early if no active ride
    if (ride == null) {
      CustomFlushbar.showError(context: context, message: 'No ride to edit');
      return;
    }

    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';
    final scheduledAt = ride['ScheduledAt'] ?? ride['scheduled_at'] ?? '';

    // Format scheduled date
    String formattedDate = 'Unknown date';
    if (scheduledAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(scheduledAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {
        AppLogger.log('Error parsing scheduled date: $e');
      }
    }

    final vehicleType =
        ride['VehicleType'] ??
        (selectedVehicle != null
            ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
            : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!]);

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
              _buildEditField('PICK UP', pickupAddress),
              SizedBox(height: 15.h),
              _buildEditField('DESTINATION', destAddress),
              SizedBox(height: 15.h),
              _buildEditField('WHEN', formattedDate),
              SizedBox(height: 15.h),
              _buildEditField(
                'PAYMENT METHOD',
                _formatPaymentMethod(paymentMethod),
              ),
              SizedBox(height: 15.h),
              _buildEditField('VEHICLE', vehicleType),
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
                        // TODO: Implement save functionality with API call
                        CustomFlushbar.showSuccess(
                          context: context,
                          message: 'Prebooking updated successfully',
                        );
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

  // Widget for stop marker
  Widget _buildStopMarkerWidget() {
    String stopText = _activeRide?['StopAddress']?.toString() ?? 'Stop';

    return Container(
      width: 200.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stop_circle, color: Colors.white, size: 16.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              stopText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
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
    // Extract data from WebSocket message format
    final rideData = ride['data'] ?? ride; // Handle both formats
    final rideId = rideData['RideID'] ?? rideData['ID'] ?? 0;
    final passengerName = rideData['PassengerName'] ?? 'Passenger';
    final pickupAddress =
        rideData['PickupAddress'] ?? 'Unknown pickup location';
    final destAddress = rideData['DestAddress'] ?? 'Unknown destination';
    final stopAddress = rideData['StopAddress'] ?? '';
    final note = rideData['Note'] ?? '';
    final price = rideData['Price']?.toString() ?? '0';
    final serviceType = rideData['ServiceType'] ?? 'taxi';
    final vehicleType = rideData['VehicleType'] ?? 'regular';
    final eta = _calculateETA(rideData);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Driver Arrival Time Timer (Left)
                // Stack(
                //   children: [
                //     Container(
                //       width: 60.w,
                //       height: 60.h,
                //       decoration: BoxDecoration(
                //         color: Color(ConstColors.mainColor),
                //         shape: BoxShape.circle,
                //       ),
                //       child: Center(
                //         child: Text(
                //           _driverArrivalTime,
                //           style: TextStyle(
                //             fontFamily: 'Inter',
                //             fontSize: 18.sp,
                //             fontWeight: FontWeight.w600,
                //             color: Colors.white,
                //           ),
                //         ),
                //       ),
                //     ),
                // White line decoration at top left
                // Positioned(
                //   top: 0,
                //   left: 0,
                //   child: Image.asset(
                //     'assets/images/whiteline.png',
                //     width: 20.w,
                //     height: 20.h,
                //     fit: BoxFit.contain,
                //   ),
                // ),
                //   ],
                // ),
                // ETA Timer and "New Order" Text (Right)
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
                          top: 0,
                          left: 11.w,
                          child: Image.asset(
                            'assets/images/whiteline.png',
                            width: 20.w,
                            height: 20.h,
                            fit: BoxFit.contain,
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
              ],
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
            Text(
              '₦$price',
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
              passengerName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Pickup: $pickupAddress',
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
              'Destination: $destAddress',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
            if (stopAddress.isNotEmpty)
              Column(
                children: [
                  SizedBox(height: 8.h),
                  Text(
                    'Stop: $stopAddress',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            SizedBox(height: 15.h),
            if (note.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note: $note',
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
                    'Pay in car', // Default payment method for new requests
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp),
                  ),
                  Spacer(),
                  Text(
                    '${serviceType.toUpperCase()} • ${vehicleType.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
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
    AppLogger.log('=== CHECKING ACTIVE RIDES ===');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      AppLogger.log('Token found, calling getActiveRides API');
      final result = await ApiService.getActiveRides(token);
      AppLogger.log('API Result: $result');

      if (result['success'] == true) {
        final rides = result['data']['rides'] as List;
        AppLogger.log('Number of active rides: ${rides.length}');

        if (rides.isNotEmpty) {
          final activeRide = rides.first;
          AppLogger.log('Active ride found: $activeRide');
          AppLogger.log('Ride Status: ${activeRide['Status']}');
          AppLogger.log('Ride ID: ${activeRide['ID']}');

          // Small delay to ensure map is initialized before showing ride
          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted) {
              _showRideAcceptedSheet(activeRide, {});
            }
          });
        } else {
          AppLogger.log('No active rides found');
        }
      } else {
        AppLogger.log('Failed to get active rides: ${result['message']}');
      }
    } else {
      AppLogger.log('No auth token found');
    }
    AppLogger.log('=== END CHECKING ACTIVE RIDES ===\n');
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

    // Always start/restart ride tracking to ensure markers are displayed
    AppLogger.log('🗺️ Starting ride tracking for accepted ride');
    RideTrackingService.startRideTracking(
      ride: ride,
      onUpdate: (markers, polylines) {
        if (mounted) {
          setState(() {
            _mapMarkers = markers;
            _mapPolylines = polylines;
          });
          _centerMapOnActiveRide();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _RideAcceptedSheet(
        ride: ride,
        acceptedData: acceptedData,
        onRideStatusChanged: (updatedRide) {
          AppLogger.log('🔔 onRideStatusChanged callback triggered');
          AppLogger.log('   Updated Status: ${updatedRide['Status']}');

          _onRideStatusChanged(updatedRide);

          AppLogger.log('📤 Closing current sheet...');
          Navigator.of(context).pop();

          AppLogger.log('🔍 Checking status for next action...');
          if (updatedRide['Status'] == 'completed') {
            AppLogger.log(
              '✅ Status is completed, scheduling completion sheet...',
            );
            Future.delayed(Duration(milliseconds: 400), () {
              AppLogger.log('⏰ Delay elapsed, checking mounted state...');
              if (mounted) {
                AppLogger.log(
                  '✅ Still mounted, calling _showCompletedSheet...',
                );
                _showCompletedSheet(context, updatedRide);
              } else {
                AppLogger.log('❌ Widget no longer mounted!');
              }
            });
          } else if (updatedRide['Status'] != 'cancelled') {
            AppLogger.log(
              '🔄 Status is ${updatedRide['Status']}, reopening sheet...',
            );
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                _showRideAcceptedSheet(updatedRide, acceptedData);
              }
            });
          } else {
            AppLogger.log('🚫 Status is cancelled, no further action');
          }
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isRideSheetVisible = false;
        });
      }
    });
  }

  void _showCompletedSheet(BuildContext context, Map<String, dynamic> ride) {
    AppLogger.log('🎉 === _showCompletedSheet CALLED ===');
    AppLogger.log('   Mounted: $mounted');
    AppLogger.log('   Ride data: $ride');

    if (!mounted) {
      AppLogger.log('❌ Widget not mounted, cannot show sheet');
      return;
    }

    final passenger = ride['Passenger'] ?? {};
    final passengerName =
        '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
    final note = ride['Note'] ?? '';
    final stopAddress = ride['StopAddress'];
    final hasStop = stopAddress != null && stopAddress.toString().isNotEmpty;

    AppLogger.log('   Passenger: $passengerName');
    AppLogger.log('   Price: ${ride['Price']}');

    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
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
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50.sp,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'Trip Completed!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 28.sp,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Amount Earned',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '₦${ride['Price']}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 36.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),
                _buildDetailRow('Passenger', passengerName),
                SizedBox(height: 15.h),
                _buildDetailRow('Pickup', ride['PickupAddress'] ?? 'Unknown'),
                if (hasStop) ...[
                  SizedBox(height: 15.h),
                  _buildDetailRow('Stop', stopAddress, isStop: true),
                ],
                SizedBox(height: 15.h),
                _buildDetailRow(
                  'Destination',
                  ride['DestAddress'] ?? 'Unknown',
                ),
                if (note.isNotEmpty) ...[
                  SizedBox(height: 15.h),
                  _buildDetailRow('Note', note),
                ],
                SizedBox(height: 15.h),
                _buildDetailRow(
                  'Payment',
                  _formatPaymentMethod(ride['PaymentMethod']),
                ),
                SizedBox(height: 30.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future.delayed(Duration(milliseconds: 200), () {
                          Navigator.push(
                            parentContext,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistoryCompletedScreen(rideId: ride['ID']),
                            ),
                          );
                        });
                      },
                      child: Center(
                        child: Text(
                          'View History',
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
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStop = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isStop ? Colors.yellow.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isStop)
                Icon(Icons.location_on, size: 16.sp, color: Colors.orange),
              if (isStop) SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                  color: isStop ? Colors.orange : Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _onRideStatusChanged(Map<String, dynamic> updatedRide) {
    AppLogger.log('=== RIDE STATUS CHANGED ===');
    AppLogger.log('Updated Ride Status: ${updatedRide['Status']}');

    if (mounted) {
      setState(() {
        _activeRide = updatedRide;
      });
    }

    // Update the tracking service with new ride status
    RideTrackingService.updateRideStatus(updatedRide);

    if (updatedRide['Status'] == 'completed' ||
        updatedRide['Status'] == 'cancelled') {
      // Clear chat messages when ride ends
      final rideId = updatedRide['ID'];
      if (rideId != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.clearMessages(rideId);
        AppLogger.log('🗑️ Cleared chat messages for ride $rideId');
      }

      // Stop tracking when ride is completed or cancelled
      AppLogger.log('Stopping tracking for completed/cancelled ride');
      RideTrackingService.stopTracking();

      // Clear the map display after completion sheet is shown
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          AppLogger.log('Clearing map markers and polylines');
          setState(() {
            _activeRide = null;
            _isRideSheetVisible = false;
            _mapMarkers = <Marker>{};
            _mapPolylines = <Polyline>{};
            _currentETA = '';
            _currentLocationName = '';
          });
        }
      });
    }

    AppLogger.log('=== RIDE STATUS CHANGE HANDLED ===\n');
  }

  Future<void> _handleEmergencySOS() async {
    try {
      AppLogger.log('🚨 Emergency SOS button tapped', tag: 'SOS');

      if (_activeRide == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'No active ride to send SOS alert',
        );
        return;
      }

      final rideId = _activeRide!['ID'];

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert to POINT format
      final location = 'POINT(${position.longitude} ${position.latitude})';

      // Get location address (you can use reverse geocoding here if needed)
      final locationAddress = _currentLocationName.isNotEmpty
          ? _currentLocationName
          : 'Lat: ${position.latitude}, Lng: ${position.longitude}';

      AppLogger.log('📍 SOS Location: $location', tag: 'SOS');
      AppLogger.log('📍 SOS Address: $locationAddress', tag: 'SOS');
      AppLogger.log('🚗 SOS Ride ID: $rideId', tag: 'SOS');

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication error. Please login again.',
        );
        return;
      }

      // Show loading indicator
      CustomFlushbar.showInfo(
        context: context,
        message: 'Sending emergency alert...',
      );

      // Send SOS alert
      final result = await ApiService.sendSOS(
        token: token,
        location: location,
        locationAddress: locationAddress,
        rideId: rideId,
      );

      if (result['success'] == true) {
        AppLogger.log('✅ SOS alert sent successfully', tag: 'SOS');
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                  SizedBox(width: 10.w),
                  Text('SOS Alert Sent'),
                ],
              ),
              content: Text(
                'Emergency alert sent successfully! Help is on the way.',
                style: TextStyle(fontSize: 16.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Color(ConstColors.mainColor),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        AppLogger.log(
          '❌ Failed to send SOS alert: ${result['message']}',
          tag: 'SOS',
        );
        // Show error dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28.sp),
                  SizedBox(width: 10.w),
                  Text('Alert Failed'),
                ],
              ),
              content: Text(
                result['message'] ??
                    'Failed to send emergency alert. Please try again.',
                style: TextStyle(fontSize: 16.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      AppLogger.log('❌ Error handling emergency SOS: $e', tag: 'SOS');
      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28.sp),
                SizedBox(width: 10.w),
                Text('Error'),
              ],
            ),
            content: Text(
              'Failed to send emergency alert. Please try again.',
              style: TextStyle(fontSize: 16.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
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
    AppLogger.log('DEBUG Passenger data: $passenger');
    final tip = widget.acceptedData['tip'] ?? 0;
    final waitFee = widget.acceptedData['wait_fee'] ?? 0;
    final passengerName =
        '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';

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
          if (_rideStatus == 'completed')
            _buildCompletedContent(passengerName)
          else
            _buildActiveRideContent(passenger, tip, waitFee, passengerName),
          if (_rideStatus == 'started')
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
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _isCompleted ? 'Trip ended' : 'End trip',
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
                GestureDetector(
                  onTap: () => _handleEmergencySOS(),
                  child: Text(
                    'Emergency Situation?',
                    style: TextStyle(
                      color: Color(ConstColors.mainColor),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
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
                        ? Color(ConstColors.mainColor)
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
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: _showGreenSlider
                                  ? Color(ConstColors.mainColor)
                                  : Color(0xFFB1B1B1),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          _showGreenSlider
                              ? 'Arrived!'
                              : (_rideStatus == 'arrived'
                                    ? (_isStarted
                                          ? 'Ride started'
                                          : 'Swipe to start')
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
      AppLogger.log('ARRIVE RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isArrived = true;
          _showGreenSlider = true;
          _sliderValue = 1.0;
        });

        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          final updatedRide = Map<String, dynamic>.from(widget.ride);
          updatedRide['Status'] = 'arrived';

          // Call the callback which will close and reopen the sheet
          widget.onRideStatusChanged(updatedRide);
        }
      } else {
        setState(() {
          _sliderValue = 0.0;
        });
        _showDistanceErrorDialog(context);
      }
    }
  }

  // Future<void> _startRide() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('auth_token');

  //   if (token != null) {
  //     final result = await ApiService.startRide(token, widget.ride['ID']);
  //     AppLogger.log('START RIDE RESPONSE: $result');

  //     if (result['success'] == true) {
  //       setState(() {
  //         _isStarted = true;
  //         _sliderValue = 1.0;
  //       });

  //       await Future.delayed(Duration(milliseconds: 800));

  //       if (mounted) {
  //         final updatedRide = Map<String, dynamic>.from(widget.ride);
  //         updatedRide['Status'] = 'started';

  //         setState(() {
  //           _sliderValue = 0.0;
  //           _isStarted = false;
  //         });

  //         widget.onRideStatusChanged(updatedRide);
  //       }
  //     } else {
  //       CustomFlushbar.showError(
  //         context: context,
  //         message: result['message'] ?? 'Failed to start ride',
  //       );
  //     }
  //   }
  // }

  Future<void> _startRide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.startRide(token, widget.ride['ID']);
      AppLogger.log('START RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isStarted = true;
          _sliderValue = 1.0;
        });

        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          final updatedRide = Map<String, dynamic>.from(widget.ride);
          updatedRide['Status'] = 'started';

          // Call the callback which will close and reopen the sheet
          widget.onRideStatusChanged(updatedRide);
        }
      } else {
        CustomFlushbar.showError(
          context: context,
          message: result['message'] ?? 'Failed to start ride',
        );
        setState(() {
          _sliderValue = 0.0;
        });
      }
    }
  }

  Future<void> _completeRide() async {
    AppLogger.log('=== COMPLETE RIDE CALLED ===');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.completeRide(token, widget.ride['ID']);
      AppLogger.log('COMPLETE RIDE API RESPONSE: $result');

      if (result['success'] == true) {
        AppLogger.log('Ride completed successfully');

        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'completed';

        // Brief animation before closing
        setState(() {
          _sliderValue = 1.0;
        });

        await Future.delayed(Duration(milliseconds: 500));

        // Update parent state - this will trigger the callback which shows the completion sheet
        widget.onRideStatusChanged(updatedRide);

        AppLogger.log('State updated and callback called');
      } else {
        AppLogger.log('Failed to complete ride: ${result['message']}');
        setState(() {
          _sliderValue = 0.0;
        });
        CustomFlushbar.showError(
          context: context,
          message: result['message'] ?? 'Failed to complete ride',
        );
      }
    }
  }

  Future<void> _handleEmergencySOS() async {
    try {
      AppLogger.log('🚨 Emergency SOS button tapped', tag: 'SOS');

      final rideId = widget.ride['ID'];

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert to POINT format
      final location = 'POINT(${position.longitude} ${position.latitude})';

      // Get location address
      final locationAddress =
          'Lat: ${position.latitude}, Lng: ${position.longitude}';

      AppLogger.log('📍 SOS Location: $location', tag: 'SOS');
      AppLogger.log('📍 SOS Address: $locationAddress', tag: 'SOS');
      AppLogger.log('🚗 SOS Ride ID: $rideId', tag: 'SOS');

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication error. Please login again.',
        );
        return;
      }

      // Show loading indicator
      CustomFlushbar.showInfo(
        context: context,
        message: 'Sending emergency alert...',
      );

      // Send SOS alert
      final result = await ApiService.sendSOS(
        token: token,
        location: location,
        locationAddress: locationAddress,
        rideId: rideId,
      );

      if (result['success'] == true) {
        AppLogger.log('✅ SOS alert sent successfully', tag: 'SOS');
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                  SizedBox(width: 10.w),
                  Text('SOS Alert Sent'),
                ],
              ),
              content: Text(
                'Emergency alert sent successfully! Help is on the way.',
                style: TextStyle(fontSize: 16.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Color(ConstColors.mainColor),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        AppLogger.log(
          '❌ Failed to send SOS alert: ${result['message']}',
          tag: 'SOS',
        );
        // Show error dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28.sp),
                  SizedBox(width: 10.w),
                  Text('Alert Failed'),
                ],
              ),
              content: Text(
                result['message'] ??
                    'Failed to send emergency alert. Please try again.',
                style: TextStyle(fontSize: 16.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      AppLogger.log('❌ Error handling emergency SOS: $e', tag: 'SOS');
      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28.sp),
                SizedBox(width: 10.w),
                Text('Error'),
              ],
            ),
            content: Text(
              'Failed to send emergency alert. Please try again.',
              style: TextStyle(fontSize: 16.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showCompletionSheet(BuildContext context, Map<String, dynamic> ride) {
    final passenger = ride['Passenger'] ?? {};
    final passengerFirstName = passenger['first_name'] ?? 'Unknown';
    final passengerLastName = passenger['last_name'] ?? '';
    final passengerName = '$passengerFirstName $passengerLastName'.trim();
    final note = ride['Note'] ?? '';
    final stopAddress = ride['StopAddress'];
    final hasStop = stopAddress != null && stopAddress.toString().isNotEmpty;
    final price = ride['Price']?.toString() ?? '0';
    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 69.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),

                // Header with icon
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50.sp,
                  ),
                ),
                SizedBox(height: 15.h),

                // Title
                Text(
                  'Trip Completed!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 28.sp,
                    color: Colors.green,
                  ),
                ),

                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),

                // Amount section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₦$price',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 32.sp,
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),

                // Passenger name section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Passenger name',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    passengerName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),

                // Destination section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Destination',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    destAddress,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Stop section (if exists)
                if (hasStop) ...[
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Stop',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20.sp,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            stopAddress,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Note section (if exists)
                if (note.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Note',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      note,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 20.h),
                Divider(thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20.h),

                // Payment method section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 20.sp, color: Colors.grey[700]),
                      SizedBox(width: 10.w),
                      Text(
                        _formatPaymentMethod(paymentMethod),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // History button
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () {
                        Navigator.of(context).pop();
                        Future.delayed(Duration(milliseconds: 200), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistoryCompletedScreen(rideId: ride['ID']),
                            ),
                          );
                        });
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
                ),

                SizedBox(height: 10.h),

                // Close button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
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
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please provide a cancellation reason',
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
        CustomFlushbar.showInfo(
          context: context,
          message: 'Ride cancelled successfully',
        );
      } else {
        CustomFlushbar.showInfo(
          context: context,
          message: result['message'] ?? 'Failed to cancel ride',
        );
      }
    }
  }

  Widget _buildActiveRideContent(
    Map<String, dynamic> passenger,
    int tip,
    int waitFee,
    String passengerName,
  ) {
    return Column(
      children: [
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
        if (_rideStatus != 'started') ...[
          Text(
            passengerName,
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
        ],
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
        if (_rideStatus != 'started') ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          driverName: passengerName,
                          rideId: widget.ride['ID'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 16.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Chat ${passenger['first_name'] ?? 'Passenger'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.41,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1.w, height: 30.h, color: Colors.grey.shade300),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          driverName: passengerName,
                          rideId: widget.ride['ID'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call, size: 16.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Call ${passenger['first_name'] ?? 'Passenger'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.41,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
        ],
      ],
    );
  }

  Widget _buildCompletedContent(String passengerName) {
    final note = widget.ride['Note'] ?? '';
    return Column(
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
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
        SizedBox(height: 20.h),
        Text(
          'Passenger name',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          passengerName,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Destination',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          widget.ride['DestAddress'] ?? 'Unknown destination',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
        if (widget.ride['StopAddress'] != null &&
            widget.ride['StopAddress'].toString().isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'Stop',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            widget.ride['StopAddress'],
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16.sp,
            ),
          ),
        ],
        if (note.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'Note',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            note,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16.sp,
            ),
          ),
        ],
        SizedBox(height: 20.h),
        Text(
          'Payment Method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          _formatPaymentMethod(widget.ride['PaymentMethod']),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoryCompletedScreen(rideId: widget.ride['ride_id']),
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
      ],
    );
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
