import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/unified_notifiation_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/home/presentation/screens/ride_sheet_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RideAcceptedSheet extends StatefulWidget {
  final Map<String, dynamic> ride;
  final Map<String, dynamic> acceptedData;
  final Function(Map<String, dynamic>) onRideStatusChanged;

  const RideAcceptedSheet({
    super.key,
    required this.ride,
    required this.acceptedData,
    required this.onRideStatusChanged,
  });

  @override
  State<RideAcceptedSheet> createState() => RideAcceptedSheetState();
}

class RideAcceptedSheetState extends State<RideAcceptedSheet> {
  double _sliderValue = 0.0;
  bool _isArrived = false;
  bool _isStarted = false;
  final bool _isCompleted = false;
  bool _showGreenSlider = false;
  String get _rideStatus => widget.ride['Status'] ?? 'accepted';

  @override
  Widget build(BuildContext context) {
    final passenger = widget.ride['Passenger'] ?? {};
    //DEBUG Passenger data: $passenger');
    final tip = widget.acceptedData['tip'] ?? 0;
    final waitFee = widget.acceptedData['wait_fee'] ?? 0;
    final passengerName =
        '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
    final passengerPhone = passenger['phone'] ?? '';
    final String passengerID = (passenger['ID'] ?? 1).toString();

    Future<void> _openGoogleMaps() async {
      try {
        // Determine which location to navigate to based on ride status
        String? destinationAddress;
        final rideStatus = _rideStatus ?? 'accepted';

        if (rideStatus == 'started') {
          // If ride has started, navigate to destination
          destinationAddress = widget.ride['DestAddress'];
        } else {
          // If ride not started (accepted or arrived), navigate to pickup
          destinationAddress = widget.ride['PickupAddress'];
        }

        if (destinationAddress == null || destinationAddress.isEmpty) {
          CustomFlushbar.showError(
            context: context,
            message: 'Location address not available',
          );
          return;
        }

        // Create Google Maps URL with the destination address
        final encodedAddress = Uri.encodeComponent(destinationAddress);
        final url =
            'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

        final uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          CustomFlushbar.showError(
            context: context,
            message: 'Could not open Google Maps',
          );
        }
      } catch (e) {
        //Error opening Google Maps: $e');
        CustomFlushbar.showError(
          context: context,
          message: 'Failed to open Google Maps',
        );
      }
    }

    return Container(
      height: 702.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation button above the white container
          if (_rideStatus != 'completed')
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.only(right: 20.w, top: 20.h, bottom: 10.h),
                child: GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation,
                          color: Colors.black,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Navigation',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Open in map',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 12.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // White container with content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SingleChildScrollView(
                // Added for scrollability
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      RideSheetContent.buildCompletedContent(
                        context: context,
                        ride: widget.ride,
                        passengerName: passengerName,
                        formatPaymentMethod: _formatPaymentMethod,
                      )
                    else
                      RideSheetContent.buildActiveRideContent(
                        context: context,
                        ride: widget.ride,
                        passenger: passenger,
                        tip: tip,
                        waitFee: waitFee,
                        passengerID: passengerID,
                        passengerName: passengerName,
                        passengerPhone: passengerPhone,
                        rideStatus: _rideStatus,
                        formatPaymentMethod: _formatPaymentMethod,
                      ),
                    if (_rideStatus == 'started')
                      Column(
                        children: [
                          SizedBox(height: 108.h),
                          Container(
                            width: 353.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Color(0xffFC6B6B),
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
                                      margin: EdgeInsets.only(
                                        right: 10.w,
                                        left: 10.w,
                                      ),
                                      width: 32.w,
                                      height: 32.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: Colors.black,
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
                                  : (_rideStatus == 'arrived' &&
                                            !_showGreenSlider
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
                                          _markAsArrived(
                                            int.parse(passengerID),
                                          );
                                        }
                                      } else {
                                        setState(() {
                                          _sliderValue = 0.0;
                                        });
                                      }
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        left: 10.w,
                                        right: 10.w,
                                      ),
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
                          if (_rideStatus != 'started' &&
                              _rideStatus != 'completed')
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
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1,
                                      ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsArrived(int ID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.arriveRide(token, widget.ride['ID']);
      //ARRIVE RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isArrived = true;
          _showGreenSlider = true;
          _sliderValue = 1.0;
        });

        // Send notification to passenger about driver arrival
        try {
          await UnifiedNotificationService.sendRideNotification(
            receiverId: ID.toString(),
            senderName: "Driver",
            messageText: "Your Driver Has Arrived at Pickup Location",
            chatRoomId: widget.ride['ID'].toString(),
          );
          //✅ Driver arrived notification sent to passenger $ID');
        } catch (e) {
          //❌ Failed to send driver arrived notification: $e');
        }

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
  //     //START RIDE RESPONSE: $result');

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
      //START RIDE RESPONSE: $result');

      if (result['success'] == true) {
        setState(() {
          _isStarted = true;
          _sliderValue = 1.0;
        });

        // Send notification to passenger about ride start
        final passengerId = widget.ride['Passenger']?['ID']?.toString();
        if (passengerId != null) {
          try {
            await UnifiedNotificationService.sendRideNotification(
              receiverId: passengerId,
              senderName: "Driver",
              messageText: "Your Ride Has Started",
              chatRoomId: widget.ride['ID'].toString(),
            );
            AppLogger.log(
              '✅ Ride started notification sent to passenger $passengerId',
            );
          } catch (e) {
            //❌ Failed to send ride started notification: $e');
          }
        }

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
    //=== COMPLETE RIDE CALLED ===');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.completeRide(token, widget.ride['ID']);
      //COMPLETE RIDE API RESPONSE: $result');

      if (result['success'] == true) {
        //Ride completed successfully');

        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'completed';

        // Brief animation before closing
        setState(() {
          _sliderValue = 1.0;
        });

        // Send notification to passenger about ride completion
        final passengerId = widget.ride['Passenger']?['ID']?.toString();
        if (passengerId != null) {
          try {
            await UnifiedNotificationService.sendRideNotification(
              receiverId: passengerId,
              senderName: "Driver",
              messageText: "Your Ride Has Been Completed",
              chatRoomId: widget.ride['ID'].toString(),
            );
            AppLogger.log(
              '✅ Ride completed notification sent to passenger $passengerId',
            );
          } catch (e) {
            //❌ Failed to send ride completed notification: $e');
          }
        }

        await Future.delayed(Duration(milliseconds: 500));

        // Update parent state - this will trigger the callback which shows the completion sheet
        widget.onRideStatusChanged(updatedRide);

        //State updated and callback called');
      } else {
        //Failed to complete ride: ${result['message']}');
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
      //🚨 Emergency SOS button tapped', tag: 'SOS');

      // ✅ FIX 1: Safely parse rideId regardless of whether it's int or String
      final rawRideId = widget.ride['ID'];
      final int? rideId = rawRideId is int
          ? rawRideId
          : int.tryParse(rawRideId?.toString() ?? '');

      if (rideId == null) {
        //❌ Invalid ride ID: $rawRideId', tag: 'SOS');
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Invalid ride ID. Please try again.',
        );
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = 'POINT(${position.longitude} ${position.latitude})';
      final locationAddress =
          'Lat: ${position.latitude}, Lng: ${position.longitude}';

      //📍 SOS Location: $location', tag: 'SOS');
      //📍 SOS Address: $locationAddress', tag: 'SOS');
      //🚗 SOS Ride ID: $rideId', tag: 'SOS');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication error. Please login again.',
        );
        return;
      }

      // ✅ FIX 2: mounted check before showing flushbar after async gap
      if (!mounted) return;
      CustomFlushbar.showInfo(
        context: context,
        message: 'Sending emergency alert...',
      );

      final result = await ApiService.sendSOS(
        token: token,
        location: location,
        locationAddress: locationAddress,
        rideId: rideId, // ✅ now guaranteed to be int
      );

      //SOS Result: $result', tag: 'SOS');

      // ✅ FIX 3: mounted check before showing dialog after async gap
      if (!mounted) return;

      if (result['success'] == true) {
        //✅ SOS alert sent successfully', tag: 'SOS');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                  SizedBox(width: 10.w),
                  const Text('SOS Alert Sent'),
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
        //❌ Failed to send SOS: ${result['message']}', tag: 'SOS');
        showDialog(
          context: context,
          barrierDismissible: false,

          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28.sp),
                  SizedBox(width: 10.w),
                  const Text('Alert Failed'),
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
      //❌ Error handling emergency SOS: $e', tag: 'SOS');
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28.sp),
                SizedBox(width: 10.w),
                const Text('Error'),
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

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Color(ConstColors.mainColor), width: 2),
        ),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cancel Ride',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Please provide a reason for cancellation:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Color(0xFFB1B1B1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter cancellation reason',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB1B1B1),
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 25.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 47.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Color(ConstColors.mainColor),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(ConstColors.mainColor),
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
                      onTap: () => _cancelRide(reasonController.text),
                      child: Container(
                        height: 47.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: 'Inter',
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
