import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/constants/url_constants.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/services/location_service.dart';
import 'package:muvam_rider/core/services/ride_tracking_service.dart';
import 'package:muvam_rider/core/services/unified_notifiation_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/communication/data/models/chat_model.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/communication/presentation/widgets/chat_notification_service.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/ride_accepted_sheet.dart';
import 'package:muvam_rider/features/home/presentation/widgets/driver_app_drawer.dart';
import 'package:muvam_rider/features/home/presentation/widgets/ride_info_widget.dart';
import 'package:muvam_rider/features/home/provider/driver_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muvam_rider/features/home/presentation/widgets/detail_row_widget.dart';
import 'package:muvam_rider/features/home/presentation/widgets/earnings_section_widget.dart';
import 'package:muvam_rider/features/home/presentation/widgets/cancel_reason_widget.dart';
import 'package:muvam_rider/features/home/presentation/widgets/edit_field_widget.dart';
import 'package:muvam_rider/features/home/presentation/widgets/vehicle_option_widget.dart';
import 'package:muvam_rider/features/home/presentation/widgets/delivery_option_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const HomeScreen({super.key, this.onOpenDrawer});

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
  final PanelController _panelController = PanelController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedCancelReason;
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(6.5244, 3.3792);
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

  late final WebSocketService _webSocketService;
  String _rideRequestETA = '--';
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
  final String _driverArrivalTime = '5';

  void _showContactBottomSheet() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
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
                  child: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: AppColors.kBlackColor,
                  ),
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
                color: AppColors.kGreyColor,
              ),
              onTap: () async {
                Navigator.pop(context);
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
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
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
                color: AppColors.kGreyColor,
              ),
              onTap: () async {
                Navigator.pop(context);
                final Uri whatsappUri = Uri.parse(
                  'https://wa.me/2347032992768',
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
      final screenHeight = MediaQuery.of(context).size.height;
      final targetPosition =
          (screenHeight * 0.42 - 80.h) / (screenHeight * 0.85 - 80.h);
      _panelController.animatePanelToPosition(
        targetPosition.clamp(0.0, 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    _webSocketService = WebSocketService.instance;
    _initializeServices();
  }

  @override
  void dispose() {
    _webSocketService.onRideRequest = null;
    _webSocketService.onRideCompleted = null;
    _webSocketService.disconnect();
    _rideCheckTimer?.cancel();
    _webSocketService.onRideCancelled = null;
    _sessionCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _callService.dispose();
    context.read<RequestProvider>().stopAutoRefresh();
    RideTrackingService.stopTracking();
    super.dispose();
  }

  void _initializeServices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isExpired = await authProvider.isSessionExpired();

    if (isExpired) {
      final refreshed = await authProvider.refreshToken();
      if (!refreshed) {
        if (mounted) {
          context.goNamedRoute(AppRoutes.onboarding.name);
        }
        return;
      }
    }

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.fetchUserProfile();

    try {
      final userId = profileProvider.userProfile?.id.toString();
      if (userId != null) {}
    } catch (e) {}

    try {
      await _webSocketService.connect();

      Future.delayed(Duration(seconds: 2), () {});
    } catch (e) {}

    _webSocketService.onChatMessage = (chatData) {
      _handleGlobalChatMessage(chatData);
    };

    if (_activeRide != null) {
      AppLogger.log(
        'Sending initialization message to open WebSocket channel...',
      );
      Future.delayed(Duration(seconds: 3), () {
        if (_webSocketService.isConnected) {
          _webSocketService.sendMessage({
            "type": "chat",
            "data": {"ride_id": _activeRide!['ID'], "message": "Hello"},
          });
        }
      });
    }

    _webSocketService.onRideCompleted = (completionData) {
      AppLogger.log('Ride completion received via WebSocket: $completionData');
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _showCompletedSheet(context, _activeRide ?? {});
          }
        });

        final updatedRide = Map<String, dynamic>.from(_activeRide ?? {});
        updatedRide['Status'] = 'completed';
        _onRideStatusChanged(updatedRide);
      }
    };

    _getCurrentLocation();

    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.initializeDriverStatus();

    _checkActiveRides();
    _fetchEarningsSummary();
    _startRideChecking();
  }

  void _handleGlobalChatMessage(Map<String, dynamic> chatData) async {
    try {
      final data = chatData['data'] ?? {};
      final messageText = data['message'] ?? '';
      final senderName = data['sender_name'] ?? 'Unknown User';
      final senderImage = data['sender_image'];
      final senderId = data['sender_id']?.toString() ?? '';
      final rideId = data['ride_id'] ?? 0;
      final timestamp =
          chatData['timestamp'] ?? DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (mounted && rideId > 0) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final message = ChatMessageModel(
          message: messageText,
          timestamp: timestamp,
          rideId: rideId,
          userId: senderId,
        );

        chatProvider.addMessage(rideId, message);

        if (senderId != currentUserId) {
          ChatNotificationService.showChatNotification(
            context,
            senderName: senderName,
            message: messageText,
            senderImage: senderImage,
            onTap: () {
              if (_activeRide != null) {
                final passenger = _activeRide!['Passenger'] ?? {};
                final passengerName =
                    '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
                final passengerImage =
                    passenger['profile_image'] ?? passenger['image'];
                final passengerId = passenger['ID'] ?? 1;
                final passengerPhone = passenger['phone'] ?? '';
                context.pushNamedRoute(
                  AppRoutes.chat.name,
                  extra: {
                    'driverId': passengerId,
                    'rideId': rideId,
                    'driverName': passengerName,
                    'driverImage': passengerImage,
                    'driverPhone': passengerPhone,
                  },
                );
              } else {
                context.pushNamedRoute(
                  AppRoutes.chat.name,
                  extra: {
                    'driverId': senderId,
                    'rideId': rideId,
                    'driverName': senderName,
                    'driverImage': senderImage,
                    'driverPhone': null,
                  },
                );
              }
            },
          );
        } else {
          AppLogger.log('Skipping notification - message is from current user');
        }
      }
    } catch (e, stack) {
      AppLogger.log('Error handling global chat message: $e');
    }
  }

  Future<void> _fetchAndSetRideETA(Map<String, dynamic> rideData) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double? pickupLat;
      double? pickupLng;

      final pickupLocationRaw =
          rideData['PickupLocation'] ?? rideData['pickup_location'];
      if (pickupLocationRaw != null) {
        final coords = _parseWKBHex(pickupLocationRaw.toString());
        if (coords != null) {
          pickupLat = coords['lat'];
          pickupLng = coords['lng'];
        }
      }

      pickupLat ??= (rideData['PickupLat'] ?? rideData['pickup_lat'])
          ?.toDouble();
      pickupLng ??= (rideData['PickupLng'] ?? rideData['pickup_lng'])
          ?.toDouble();

      if (pickupLat == null || pickupLng == null) {
        if (mounted) setState(() => _rideRequestETA = '--');
        return;
      }

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        pickupLat,
        pickupLng,
      );

      final minutes = ((distanceMeters / 1000 / 30) * 60).round();
      final eta = minutes < 1 ? '<1' : '$minutes';

      if (mounted) setState(() => _rideRequestETA = eta);
    } catch (e) {
      AppLogger.log('ETA fetch error: $e');
      if (mounted) setState(() => _rideRequestETA = '--');
    }
  }

  Map<String, double>? _parseWKBHex(String hex) {
    try {
      if (hex.length < 50) return null;
      final byteOrder = int.parse(hex.substring(0, 2), radix: 16);
      final isLittleEndian = byteOrder == 1;
      final lngHex = hex.substring(18, 34);
      final latHex = hex.substring(34, 50);
      final lng = _hexToDouble(lngHex, isLittleEndian);
      final lat = _hexToDouble(latHex, isLittleEndian);
      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    } catch (e) {
      return null;
    }
  }

  double? _hexToDouble(String hex, bool isLittleEndian) {
    try {
      if (hex.length != 16) return null;
      final bytes = List<int>.generate(
        8,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      );
      final ordered = isLittleEndian ? bytes.reversed.toList() : bytes;
      int bits = 0;
      for (final byte in ordered) bits = (bits << 8) | byte;
      final byteData = ByteData(8);
      byteData.setInt64(0, bits);
      return byteData.getFloat64(0);
    } catch (e) {
      return null;
    }
  }

  void _startRideChecking() {
    _webSocketService.onRideRequest = (rideData) {
      final driverProvider = Provider.of<DriverProvider>(
        context,
        listen: false,
      );
      if (driverProvider.isOnline && !_hasActiveRequest && mounted) {
        final data = rideData['data'] ?? rideData;
        setState(() {
          _nearbyRides = [rideData];
          _currentRideIndex = 0;
          _hasActiveRequest = true;
          _rideRequestETA = '...';
        });
        _fetchAndSetRideETA(data);
      }
    };

    _webSocketService.onRideCancelled = (cancelData) {
      AppLogger.log('Ride cancelled by passenger: $cancelData');
      if (mounted) {
        final data = cancelData['data'] ?? cancelData;
        final cancelledRideId = data['RideID'] ?? data['ID'] ?? data['ride_id'];

        if (_hasActiveRequest && _nearbyRides.isNotEmpty) {
          setState(() {
            _hasActiveRequest = false;
            _nearbyRides.clear();
            _currentRideIndex = 0;
            _rideRequestETA = '--';
          });
        }

        if (_activeRide != null) {
          final activeRideId = _activeRide!['ID'];
          if (cancelledRideId == null || cancelledRideId == activeRideId) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            _onRideStatusChanged({..._activeRide!, 'Status': 'cancelled'});
          }
        }
        CustomFlushbar.showError(
          context: context,
          message: 'Ride was cancelled by the passenger',
        );
      }
    };

    _rideCheckTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      final driverProvider = Provider.of<DriverProvider>(
        context,
        listen: false,
      );
      if (driverProvider.isOnline && !_hasActiveRequest) {
        _checkNearbyRides();
      }
    });
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
        AppLogger.log('Session expired in timer, attempting token refresh...');
        final refreshed = await authProvider.refreshToken();
        if (!refreshed) {
          timer.cancel();
          if (mounted) {
            context.goNamedRoute(AppRoutes.onboarding.name);
          }
        } else {}
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
            'Driver location updated: ${position.latitude}, ${position.longitude}',
          );
        }
      }
    } catch (e) {}
  }

  Future<void> _checkNearbyRides() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.getNearbyRides(token);

      if (result['success'] == false) {
        final errorMessage = result['message']?.toString().toLowerCase() ?? '';
        if (errorMessage.contains('invalid token') ||
            errorMessage.contains('token')) {
          await _handleInvalidToken();
          return;
        }
      }

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

  Future<void> _handleInvalidToken() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final refreshed = await authProvider.refreshToken();

      if (refreshed) {
        AppLogger.log(
          'Token refreshed successfully after invalid token detection.',
        );
        return;
      }
      _rideCheckTimer?.cancel();
      _sessionCheckTimer?.cancel();
      _locationUpdateTimer?.cancel();
      _webSocketService.disconnect();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        CustomFlushbar.showError(
          context: context,
          message: 'Session expired. Please login again.',
        );
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          context.goNamedRoute(AppRoutes.onboarding.name);
        }
      }
    } catch (e) {}
  }

  Future<void> _acceptRide() async {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length)
      return;
    final ride = _nearbyRides[_currentRideIndex];
    final rideData = ride['data'] ?? ride;
    final rideId = rideData['RideID'] ?? rideData['ID'] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final result = await ApiService.acceptRide(token, rideId);
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _hasActiveRequest = false;
            _nearbyRides.clear();
            _rideRequestETA = '--';
          });
        }
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
          'PickupLocation': rideData['PickupLocation'],
          'DestLocation': rideData['DestLocation'],
          'PickupAddress': rideData['PickupAddress'] ?? 'Unknown pickup',
          'DestAddress': rideData['DestAddress'] ?? 'Unknown destination',
          'data': rideData,
        };
        final passengerId =
            transformedRide['Passenger']['ID']?.toString() ??
            rideData['Passenger']?['ID']?.toString() ??
            rideData['PassengerID']?.toString();
        if (passengerId != null) {
          try {
            await UnifiedNotificationService.sendRideNotification(
              receiverId: passengerId,
              senderName: "Driver",
              messageText: "A Driver Has Accepted Your Ride And is On The Way",
              chatRoomId: rideId.toString(),
            );
            AppLogger.log(
              'Ride accepted notification sent to passenger $passengerId',
            );
          } catch (e) {}
        }
        AppLogger.log("PASSENGER ID ${transformedRide['Passenger']['ID']}");
        AppLogger.log(
          '   PickupLocation: ${transformedRide['PickupLocation']}',
        );
        if (transformedRide['PickupLocation'] == null ||
            transformedRide['DestLocation'] == null) {
          AppLogger.log('Location coordinates missing, geocoding addresses...');
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
      final pickupUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(pickupAddress)}&key=${UrlConstants.googleMapsApiKey}',
      );
      final pickupResponse = await http.get(pickupUrl);
      final pickupData = json.decode(pickupResponse.body);
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
        final pickupWKB = 'POINT($pickupLng $pickupLat)';
        final destWKB = 'POINT($destLng $destLat)';

        ride['PickupLocation'] = pickupWKB;
        ride['DestLocation'] = destWKB;

        if (ride['data'] != null) {
          ride['data']['PickupLocation'] = pickupWKB;
          ride['data']['DestLocation'] = destWKB;
        }

        _showRideAcceptedSheet(ride, acceptedData);
      } else {
        _showRideAcceptedSheet(ride, acceptedData);
      }
    } catch (e) {
      _showRideAcceptedSheet(ride, acceptedData);
    }
  }

  Future<void> _declineRide() async {
    if (_nearbyRides.isEmpty || _currentRideIndex >= _nearbyRides.length)
      return;
    final ride = _nearbyRides[_currentRideIndex];
    final rideData = ride['data'] ?? ride;
    final rideId = rideData['RideID'] ?? rideData['ID'] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final result = await ApiService.rejectRide(token, rideId);
      if (result['success'] == true) {
      } else {}
    }
    if (mounted) {
      setState(() {
        _currentRideIndex++;
        if (_currentRideIndex >= _nearbyRides.length) {
          _hasActiveRequest = false;
          _nearbyRides.clear();
          _currentRideIndex = 0;
          _rideRequestETA = '--';
        }
      });
    }
  }

  String _calculateETA(Map<String, dynamic> ride) {
    try {
      final rideData = ride['data'] ?? ride;
      double? pickupLat;
      double? pickupLng;
      final pickupLocationRaw =
          rideData['PickupLocation'] ?? rideData['pickup_location'];
      if (pickupLocationRaw != null) {
        final pointStr = pickupLocationRaw.toString();
        final match = RegExp(
          r'POINT\(([^\s]+)\s+([^\)]+)\)',
        ).firstMatch(pointStr);
        if (match != null) {
          pickupLng = double.tryParse(match.group(1) ?? '');
          pickupLat = double.tryParse(match.group(2) ?? '');
        }
      }
      pickupLat ??= double.tryParse(
        (rideData['PickupLat'] ?? rideData['pickup_lat'] ?? '').toString(),
      );
      pickupLng ??= double.tryParse(
        (rideData['PickupLng'] ?? rideData['pickup_lng'] ?? '').toString(),
      );
      if (pickupLat == null ||
          pickupLng == null ||
          pickupLat == 0.0 ||
          pickupLng == 0.0) {
        AppLogger.log(
          'ETA: No valid pickup coordinates found, showing placeholder',
        );
        return '--';
      }
      final distanceMeters = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        pickupLat,
        pickupLng,
      );
      final distanceKm = distanceMeters / 1000;
      final timeMinutes = ((distanceKm / 30) * 60).round();
      if (timeMinutes < 1) return '< 1 min';
      if (timeMinutes == 1) return '1 min';
      return '$timeMinutes mins';
    } catch (e) {
      return '--';
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

  int get _activeRequestsCount {
    final requestProvider = context.watch<RequestProvider>();

    final activeCount = requestProvider.activeRides.length;
    final prebookedCount = requestProvider.prebookedRides.length;

    return activeCount + prebookedCount;
  }

  void _centerMapOnActiveRide() {
    if (_activeRide == null || _mapController == null) {
      AppLogger.log(
        'Cannot center map: activeRide=${_activeRide != null}, mapController=${_mapController != null}',
      );
      return;
    }
    try {
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
            'Map centered on pickup marker: ${pickupMarker.position}',
          );
          return;
        }
        final anyMarker = _mapMarkers.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(anyMarker.position, 14),
        );
        AppLogger.log(
          'Map centered on available marker: ${anyMarker.position}',
        );
      } else {}
    } catch (e) {}
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
        drawer: DriverAppDrawer(onContactUsTap: _showContactBottomSheet),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                RideTrackingService.setMapController(controller);
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
                                    ? AppColors.kMainColor
                                    : AppColors.kGreyColor.withOpacity(0.3),
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
                                                AppColors.kWhiteColor,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Online',
                                        style: TextStyle(
                                          color: AppColors.kWhiteColor,
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
                                    ? AppColors.kError
                                    : AppColors.kGreyColor.withOpacity(0.3),
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
                                                AppColors.kWhiteColor,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Offline',
                                        style: TextStyle(
                                          color: AppColors.kWhiteColor,
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
            Positioned(
              top: 50.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => widget.onOpenDrawer?.call(),
                child: Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: AppColors.kWhiteColor,
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    Icons.menu,
                    size: 24.sp,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50.h,
              right: 20.w,
              child: GestureDetector(
                onTap: () {
                  if (_activeRide != null) {
                    _centerMapOnActiveRide();
                  } else {
                    _getCurrentLocation();
                  }
                },
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: AppColors.kWhiteColor,
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    _activeRide != null
                        ? Icons.directions_car
                        : Icons.my_location,
                    size: 24.sp,
                    color: AppColors.kMainColor,
                  ),
                ),
              ),
            ),
            if (_activeRide != null &&
                _activeRide!['StopAddress'] != null &&
                _activeRide!['StopAddress'].toString().isNotEmpty)
              Positioned(
                top: 120.h,
                left: 0,
                right: 0,
                child: Center(child: _buildStopMarkerWidget()),
              ),
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 80.h,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              panelSnapping: false,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              color: themeManager.getCardColor(context),
              panelBuilder: (ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: themeManager.getCardColor(context),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.r),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          width: 69.w,
                          height: 5.h,
                          margin: EdgeInsets.symmetric(vertical: 11.75.h),
                          decoration: BoxDecoration(
                            color: AppColors.kGreyColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5.r),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            Container(
                              width: 353.w,
                              height: 50.h,
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              decoration: BoxDecoration(
                                color: AppColors.kGreyColor.withOpacity(0.12),
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
                            EarningsSectionWidget(
                              title: 'Today\'s earning',
                              value: '₦${_earningsData['total_earnings']}',
                              onTap: () => context.pushNamedRoute(
                                AppRoutes.analytics.name,
                              ),
                            ),
                            Divider(
                              color: AppColors.kGreyColor.withOpacity(0.3),
                              thickness: 1,
                            ),
                            EarningsSectionWidget(
                              title: 'Today\'s rides',
                              value: '${_earningsData['total_rides']}',
                              onTap: () => context.pushNamedRoute(
                                AppRoutes.analytics.name,
                              ),
                            ),
                            Divider(
                              color: AppColors.kGreyColor.withOpacity(0.3),
                              thickness: 1,
                            ),
                            EarningsSectionWidget(
                              title: 'Total ride completed',
                              value:
                                  '${_earningsData['total_rides_completed']}',
                              onTap: () => context.pushNamedRoute(
                                AppRoutes.analytics.name,
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_activeRide != null && _currentETA.isNotEmpty)
              RideInfoWidget(
                eta: _currentETA,
                location: _currentLocationName,
                rideStatus: _activeRide!['Status'] ?? 'accepted',
              ),
            if (_activeRide != null && !_isRideSheetVisible)
              Positioned(
                bottom: 120.h,
                right: 20.w,
                child: Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.kMainColor,
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
                          color: AppColors.kWhiteColor,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_hasActiveRequest && _nearbyRides.isNotEmpty) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    color: AppColors.kBlackColor.withOpacity(0.5),
                  ),
                ),
              ),
              _buildRideRequestSheet(),
            ],
          ],
        ),
      ),
    );
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
            color: AppColors.kWhiteColor,
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
                    color: AppColors.kGreyColor.withOpacity(0.3),
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
                      child: Icon(
                        Icons.close,
                        size: 24.sp,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Divider(
                  thickness: 1,
                  color: AppColors.kGreyColor.withOpacity(0.3),
                ),
                SizedBox(height: 20.h),
                VehicleOptionWidget(
                  index: 0,
                  title: 'Regular vehicle',
                  subtitle: '20 min | 4 passengers',
                  price: '₦12,000',
                  selectedVehicle: selectedVehicle,
                  onTap: () {
                    setState(() {
                      selectedVehicle = 0;
                      selectedDelivery = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 15.h),
                VehicleOptionWidget(
                  index: 1,
                  title: 'Fancy vehicle',
                  subtitle: '20 min | 4 passengers',
                  price: '₦12,000',
                  selectedVehicle: selectedVehicle,
                  onTap: () {
                    setState(() {
                      selectedVehicle = 1;
                      selectedDelivery = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 15.h),
                VehicleOptionWidget(
                  index: 2,
                  title: 'VIP',
                  subtitle: '20 min | 4 passengers',
                  price: '₦12,000',
                  selectedVehicle: selectedVehicle,
                  onTap: () {
                    setState(() {
                      selectedVehicle = 2;
                      selectedDelivery = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 30.h),
                Text('Delivery service', style: ConstTextStyles.deliveryTitle),
                SizedBox(height: 20.h),
                DeliveryOptionWidget(
                  index: 0,
                  title: 'Bicycle',
                  subtitle: '20 min',
                  price: '₦12,000',
                  imagePath: ConstImages.bike,
                  selectedDelivery: selectedDelivery,
                  onTap: () {
                    setState(() {
                      selectedDelivery = 0;
                      selectedVehicle = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 15.h),
                DeliveryOptionWidget(
                  index: 1,
                  title: 'Vehicle',
                  subtitle: '20 min',
                  price: '₦12,000',
                  imagePath: ConstImages.car,
                  selectedDelivery: selectedDelivery,
                  onTap: () {
                    setState(() {
                      selectedDelivery = 1;
                      selectedVehicle = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 15.h),
                DeliveryOptionWidget(
                  index: 2,
                  title: 'Motor bike',
                  subtitle: '20 min',
                  price: '₦12,000',
                  imagePath: ConstImages.car,
                  selectedDelivery: selectedDelivery,
                  onTap: () {
                    setState(() {
                      selectedDelivery = 2;
                      selectedVehicle = null;
                    });
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 30.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: (selectedVehicle != null || selectedDelivery != null)
                        ? AppColors.kMainColor
                        : AppColors.kGreyColor,
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
                          color: AppColors.kWhiteColor,
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
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              GestureDetector(
                onTap: () => _showAddNoteSheet(),
                child: Column(
                  children: [
                    Icon(
                      Icons.message,
                      size: 25.67.w,
                      color: AppColors.kBlackColor,
                    ),
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
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                          color: AppColors.kGreyColor,
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
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: AppColors.kGreyColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: AppColors.kGreyColor,
                    ),
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
                        color: AppColors.kWhiteColor,
                        border: Border.all(color: AppColors.kMainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Book Later',
                          style: TextStyle(
                            color: AppColors.kMainColor,
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
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            color: AppColors.kWhiteColor,
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
                color: AppColors.kGreyColor.withOpacity(0.3),
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
                    color: AppColors.kBlackColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildPaymentOption('Pay with wallet'),
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
            _buildPaymentOption('Pay with card'),
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
            _buildPaymentOption('pay4me'),
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
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
            if (isSelected)
              Icon(Icons.check, color: AppColors.kSuccessColor, size: 20.sp),
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
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Text(
                'Add note',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 350.w,
                height: 111.h,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.2),
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
                      ? AppColors.kMainColor
                      : AppColors.kGreyColor,
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
                        color: AppColors.kWhiteColor,
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
            color: AppColors.kWhiteColor,
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
                    color: AppColors.kGreyColor.withOpacity(0.3),
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
                      color: AppColors.kBlackColor,
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
                    color: AppColors.kBlackColor,
                  ),
                ),
                SizedBox(height: 20.h),
                Divider(
                  thickness: 1,
                  color: AppColors.kGreyColor.withOpacity(0.3),
                ),
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
                      color: AppColors.kGreyColor,
                    ),
                  ),
                  subtitle: Text(
                    '${_getWeekday(selectedDate.weekday)} ${_getMonth(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                    style: ConstTextStyles.vehicleTitle,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: AppColors.kGreyColor,
                  ),
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
                Divider(
                  thickness: 1,
                  color: AppColors.kGreyColor.withOpacity(0.3),
                ),
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
                      color: AppColors.kGreyColor,
                    ),
                  ),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: ConstTextStyles.vehicleTitle,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: AppColors.kGreyColor,
                  ),
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
                        color: AppColors.kWhiteColor,
                        border: Border.all(color: AppColors.kMainColor),
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
                              color: AppColors.kMainColor,
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
                        color: AppColors.kMainColor,
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
                              color: AppColors.kWhiteColor,
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
          color: AppColors.kWhiteColor,
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
                  color: AppColors.kGreyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Text(
                'Booking request successful',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
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
                  color: AppColors.kBlackColor,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.1),
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
                            color: AppColors.kMainColor,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(
                      thickness: 1,
                      color: AppColors.kGreyColor.withOpacity(0.3),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.kError,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
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
                  color: AppColors.kMainColor,
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
                        color: AppColors.kWhiteColor,
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
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: AppColors.kGreyColor.withOpacity(0.3),
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
                color: AppColors.kBlackColor,
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
                color: AppColors.kBlackColor,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
            SizedBox(height: 20.h),
            SizedBox(
              width: 353.w,
              height: 10.h,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.kGreyColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.kMainColor),
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.kMainColor,
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
                      color: AppColors.kWhiteColor,
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

    final ride = _activeRide;

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
    final passengerID = passenger['ID'] ?? 1;
    final passengerPhone = passenger['phone'] ?? '';

    final passengerName = '$passengerFirstName $passengerLastName'.trim();
    final passengerImage =
        passenger['profile_image'] ?? passenger['image'] ?? '';
    final rideId = ride['ID'];
    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final price = ride['Price']?.toString() ?? '0';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';
    final createdAt = ride['CreatedAt'] ?? ride['created_at'] ?? '';

    String formattedDate = 'Unknown date';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {}
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
          color: AppColors.kWhiteColor,
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
                  color: AppColors.kGreyColor.withOpacity(0.3),
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
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.1),
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
                            color: AppColors.kMainColor,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(
                      thickness: 1,
                      color: AppColors.kGreyColor.withOpacity(0.3),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.kError,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                      color: AppColors.kBlackColor,
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
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: AppColors.kGreyColor.withOpacity(0.3),
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                        color: AppColors.kBlackColor,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦$price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kBlackColor,
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
                            Icon(
                              Icons.edit,
                              size: 16.sp,
                              color: AppColors.kBlackColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Modify Trip',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: AppColors.kBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 30.h,
                      color: AppColors.kGreyColor.withOpacity(0.3),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.pushNamedRoute(
                            AppRoutes.chat.name,
                            extra: {
                              'driverId': passengerID,
                              'rideId': rideId,
                              'driverName': passengerName,
                              'driverImage': passengerImage.isNotEmpty
                                  ? passengerImage
                                  : null,
                              'driverPhone': passengerPhone,
                            },
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat,
                              size: 16.sp,
                              color: AppColors.kBlackColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Chat Passenger',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: AppColors.kBlackColor,
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

    final ride = _activeRide;

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

    String formattedDate = 'Unknown date';
    if (scheduledAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(scheduledAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {}
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
          color: AppColors.kWhiteColor,
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
                  color: AppColors.kGreyColor.withOpacity(0.3),
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
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.1),
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
                            color: AppColors.kMainColor,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(
                      thickness: 1,
                      color: AppColors.kGreyColor.withOpacity(0.3),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.kError,
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                      color: AppColors.kBlackColor,
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
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: AppColors.kGreyColor.withOpacity(0.3),
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
                            color: AppColors.kBlackColor,
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
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                thickness: 1,
                color: AppColors.kGreyColor.withOpacity(0.3),
              ),
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
                        color: AppColors.kBlackColor,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦$price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kBlackColor,
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
                  color: AppColors.kMainColor,
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
                        color: AppColors.kWhiteColor,
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
    final ride = _activeRide;

    if (ride == null) {
      CustomFlushbar.showError(context: context, message: 'No ride to edit');
      return;
    }

    final pickupAddress = ride['PickupAddress'] ?? 'Unknown pickup';
    final destAddress = ride['DestAddress'] ?? 'Unknown destination';
    final paymentMethod = ride['PaymentMethod'] ?? 'in_car';
    final scheduledAt = ride['ScheduledAt'] ?? ride['scheduled_at'] ?? '';

    String formattedDate = 'Unknown date';
    if (scheduledAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(scheduledAt);
        formattedDate =
            '${_getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
      } catch (e) {}
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
          color: AppColors.kWhiteColor,
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
                  color: AppColors.kGreyColor.withOpacity(0.3),
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
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              EditFieldWidget(label: 'PICK UP', value: pickupAddress),
              SizedBox(height: 15.h),
              EditFieldWidget(label: 'DESTINATION', value: destAddress),
              SizedBox(height: 15.h),
              EditFieldWidget(label: 'WHEN', value: formattedDate),
              SizedBox(height: 15.h),
              EditFieldWidget(
                label: 'PAYMENT METHOD',
                value: _formatPaymentMethod(paymentMethod),
              ),
              SizedBox(height: 15.h),
              EditFieldWidget(label: 'VEHICLE', value: vehicleType),
              SizedBox(height: 40.h),
              Column(
                children: [
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.kWhiteColor,
                      border: Border.all(color: AppColors.kError),
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
                            color: AppColors.kError,
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
                      color: AppColors.kMainColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        CustomFlushbar.showSuccess(
                          context: context,
                          message: 'Prebooking updated successfully',
                        );
                      },
                      child: Center(
                        child: Text(
                          'Save prebooking',
                          style: TextStyle(
                            color: AppColors.kWhiteColor,
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
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.3),
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
                    color: AppColors.kBlackColor,
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
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              CancelReasonWidget(
                index: 0,
                reason: 'I am taking alternative transport',
                selectedCancelReason: selectedCancelReason,
                onReasonSelected: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonWidget(
                index: 1,
                reason: 'It is taking too long to get a driver',
                selectedCancelReason: selectedCancelReason,
                onReasonSelected: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonWidget(
                index: 2,
                reason: 'I have to attend to something',
                selectedCancelReason: selectedCancelReason,
                onReasonSelected: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonWidget(
                index: 3,
                reason: 'Others',
                selectedCancelReason: selectedCancelReason,
                onReasonSelected: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              Spacer(),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: selectedCancelReason != null
                      ? AppColors.kMainColor
                      : AppColors.kGreyColor,
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
                        color: AppColors.kWhiteColor,
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
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 30.h),
              decoration: BoxDecoration(
                color: AppColors.kGreyColor.withOpacity(0.3),
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
                color: AppColors.kMainColor,
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
                      color: AppColors.kWhiteColor,
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
          Icon(Icons.stop_circle, color: AppColors.kWhiteColor, size: 16.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              stopText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.kWhiteColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
    final rideData = ride['data'] ?? ride;
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: 393.w,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
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
                Row(
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 60.h,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              color: AppColors.kMainColor,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _rideRequestETA,
                                  style: TextStyle(
                                    color: AppColors.kWhiteColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'min',
                                  style: TextStyle(
                                    color: AppColors.kWhiteColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(8),
                            width: 60.w,
                            height: 60.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.kWhiteColor,
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      'New Order',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: AppColors.kGreyColor.withOpacity(0.3)),
            SizedBox(height: 15.h),
            Text(
              '₦$price',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 36.sp,
                height: 1.0,
                letterSpacing: -0.32,
                color: AppColors.kBlackColor,
              ),
            ),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                passengerName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: AppColors.kBlackColor,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pickup: $pickupAddress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: AppColors.kBlackColor,
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Destination: $destAddress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: AppColors.kBlackColor,
                ),
              ),
            ),
            SizedBox(height: 15.h),
            if (stopAddress.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stop: $stopAddress',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 24.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),

            SizedBox(height: 15.h),
            if (note.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,

                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Note:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlackColor,
                        ),
                      ),
                    ),
                    Text(
                      '$note',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 15.h),

            Container(
              width: 353.w,
              height: 42.h,
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  width: 0.6,
                  color: AppColors.kGreyColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(ConstImages.wallet, width: 20.w, height: 20.h),
                  SizedBox(width: 8.w),
                  Text(
                    'Pay in car',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${serviceType.toUpperCase()} • ${vehicleType.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      color: AppColors.kSubtitleColor,
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
                        color: AppColors.kError,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            color: AppColors.kWhiteColor,
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
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            color: AppColors.kWhiteColor,
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.getActiveRides(token);

      if (result['success'] == true) {
        final rides = result['data']['rides'] as List;

        if (rides.isNotEmpty) {
          final activeRide = rides.first;

          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted) {
              _showRideAcceptedSheet(activeRide, {});
            }
          });
        } else {}
      } else {}
    } else {}
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
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => RideAcceptedSheet(
        ride: ride,
        acceptedData: acceptedData,
        onRideStatusChanged: (updatedRide) {
          _onRideStatusChanged(updatedRide);

          Navigator.of(context).pop();

          if (updatedRide['Status'] == 'completed') {
            AppLogger.log(
              'Status is completed, scheduling completion sheet...',
            );
            Future.delayed(Duration(milliseconds: 400), () {
              if (mounted) {
                AppLogger.log('Still mounted, calling _showCompletedSheet...');
                _showCompletedSheet(context, updatedRide);
              } else {}
            });
          } else if (updatedRide['Status'] != 'cancelled') {
            AppLogger.log(
              'Status is ${updatedRide['Status']}, reopening sheet...',
            );
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                _showRideAcceptedSheet(updatedRide, acceptedData);
              }
            });
          } else {}
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
    if (!mounted) {
      return;
    }

    final passenger = ride['Passenger'] ?? {};
    final passengerName =
        '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
    final note = ride['Note'] ?? '';
    final stopAddress = ride['StopAddress'];
    final hasStop = stopAddress != null && stopAddress.toString().isNotEmpty;

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
            color: AppColors.kWhiteColor,
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
                    color: AppColors.kGreyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppColors.kSuccessColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.kSuccessColor,
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
                    color: AppColors.kSuccessColor,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Amount Earned',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: AppColors.kSubtitleColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '₦${double.tryParse(ride['Price']?.toString() ?? '0')?.toString() ?? ride['Price']}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 36.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: AppColors.kMainColor,
                  ),
                ),
                SizedBox(height: 20.h),
                Divider(
                  thickness: 1,
                  color: AppColors.kGreyColor.withOpacity(0.3),
                ),
                SizedBox(height: 20.h),
                DetailRowWidget(label: 'Passenger', value: passengerName),
                SizedBox(height: 15.h),
                DetailRowWidget(
                  label: 'Pickup',
                  value: ride['PickupAddress'] ?? 'Unknown',
                ),
                if (hasStop) ...[
                  SizedBox(height: 15.h),
                  DetailRowWidget(
                    label: 'Stop',
                    value: stopAddress,
                    isStop: true,
                  ),
                ],
                SizedBox(height: 15.h),
                DetailRowWidget(
                  label: 'Destination',
                  value: ride['DestAddress'] ?? 'Unknown',
                ),
                if (note.isNotEmpty) ...[
                  SizedBox(height: 15.h),
                  DetailRowWidget(label: 'Note', value: note),
                ],
                SizedBox(height: 15.h),
                DetailRowWidget(
                  label: 'Payment',
                  value: _formatPaymentMethod(ride['PaymentMethod']),
                ),
                SizedBox(height: 30.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.kMainColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future.delayed(Duration(milliseconds: 200), () {
                          parentContext.pushNamedRoute(
                            AppRoutes.historyCompleted.name,
                            extra: {'rideId': ride['ID']},
                          );
                        });
                      },
                      child: Center(
                        child: Text(
                          'View History',
                          style: TextStyle(
                            color: AppColors.kWhiteColor,
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
                    style: TextStyle(
                      color: AppColors.kSubtitleColor,
                      fontSize: 14.sp,
                    ),
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

  void _onRideStatusChanged(Map<String, dynamic> updatedRide) {
    if (mounted) {
      setState(() {
        _activeRide = updatedRide;
      });
    }

    RideTrackingService.updateRideStatus(updatedRide);

    if (updatedRide['Status'] == 'completed' ||
        updatedRide['Status'] == 'cancelled') {
      final rideId = updatedRide['ID'];
      if (rideId != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.clearMessages(rideId);
      }

      RideTrackingService.stopTracking();

      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
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
  }

  Future<void> _handleEmergencySOS() async {
    try {
      if (_activeRide == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'No active ride to send SOS alert',
        );
        return;
      }

      final rideId = _activeRide!['ID'];

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = 'POINT(${position.longitude} ${position.latitude})';

      final locationAddress = _currentLocationName.isNotEmpty
          ? _currentLocationName
          : 'Lat: ${position.latitude}, Lng: ${position.longitude}';

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication error. Please login again.',
        );
        return;
      }

      CustomFlushbar.showInfo(
        context: context,
        message: 'Sending emergency alert...',
      );

      final result = await ApiService.sendSOS(
        token: token,
        location: location,
        locationAddress: locationAddress,
        rideId: rideId,
      );

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.kSuccessColor,
                    size: 28.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'SOS Alert Sent',
                    style: TextStyle(color: AppColors.kBlackColor),
                  ),
                ],
              ),
              content: Text(
                'Emergency alert sent successfully! Help is on the way.',
                style: TextStyle(fontSize: 16.sp, color: AppColors.kBlackColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: AppColors.kMainColor,
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
          'Failed to send SOS alert: ${result['message']}',
          tag: 'SOS',
        );
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: AppColors.kError, size: 28.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'Alert Failed',
                    style: TextStyle(color: AppColors.kBlackColor),
                  ),
                ],
              ),
              content: Text(
                result['message'] ??
                    'Failed to send emergency alert. Please try again.',
                style: TextStyle(fontSize: 16.sp, color: AppColors.kBlackColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: AppColors.kError,
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: AppColors.kError, size: 28.sp),
                SizedBox(width: 10.w),
                Text('Error', style: TextStyle(color: AppColors.kBlackColor)),
              ],
            ),
            content: Text(
              'Failed to send emergency alert. Please try again.',
              style: TextStyle(fontSize: 16.sp, color: AppColors.kBlackColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.kError,
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
