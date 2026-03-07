import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
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
    final tip = widget.acceptedData['tip'] ?? 0;
    final waitFee = widget.acceptedData['wait_fee'] ?? 0;
    final passengerName =
        '${passenger['first_name'] ?? 'Unknown'} ${passenger['last_name'] ?? 'Passenger'}';
    final passengerPhone = passenger['phone'] ?? '';
    final String passengerID = (passenger['ID'] ?? 1).toString();

    Future<void> _openGoogleMaps() async {
      try {
        String? destinationAddress;
        final rideStatus = _rideStatus ?? 'accepted';

        if (rideStatus == 'started') {
          destinationAddress = widget.ride['DestAddress'];
        } else {
          destinationAddress = widget.ride['PickupAddress'];
        }

        if (destinationAddress == null || destinationAddress.isEmpty) {
          CustomFlushbar.showError(
            context: context,
            message: 'Location address not available',
          );
          return;
        }

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
                      color: AppColors.kWhiteColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation,
                          color: AppColors.kBlackColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MuvamTexts.bodySmall12(
                              context,
                              text: 'Navigation',
                              isTextWidget: true,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kBlackColor,
                            ),
                            MuvamTexts.bodySmall12(
                              context,
                              text: 'Open in map',
                              isTextWidget: true,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.kBlackColor,
                          size: 12.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.kWhiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SingleChildScrollView(
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
                              color: const Color(0xffFC6B6B),
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
                                        color: AppColors.kWhiteColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: AppColors.kBlackColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: MuvamTexts.button16(
                                    context,
                                    text: _isCompleted
                                        ? 'Trip ended'
                                        : 'End trip',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kWhiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: () => _handleEmergencySOS(),
                            child: MuvamTexts.bodyMedium14(
                              context,
                              text: 'Emergency Situation?',
                              isTextWidget: true,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kMainColor,
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
                                  ? AppColors.kMainColor
                                  : (_rideStatus == 'arrived' &&
                                            !_showGreenSlider
                                        ? AppColors.kGreyColor
                                        : AppColors.kGreyColor),
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
                                        color: AppColors.kWhiteColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: _showGreenSlider
                                            ? AppColors.kMainColor
                                            : AppColors.kGreyColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: MuvamTexts.button16(
                                    context,
                                    text: _showGreenSlider
                                        ? 'Arrived!'
                                        : (_rideStatus == 'arrived'
                                              ? (_isStarted
                                                    ? 'Ride started'
                                                    : 'Swipe to start')
                                              : 'Slide to mark as arrived'),
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kWhiteColor,
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
                                      color: AppColors.kWhiteColor,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.kFailureColor,
                                        width: 1,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(10.w),
                                    child: Center(
                                      child: MuvamTexts.button16(
                                        context,
                                        text: 'Cancel ride',
                                        isTextWidget: true,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kFailureColor,
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

      if (result['success'] == true) {
        setState(() {
          _isArrived = true;
          _showGreenSlider = true;
          _sliderValue = 1.0;
        });

        try {
          await UnifiedNotificationService.sendRideNotification(
            receiverId: ID.toString(),
            senderName: "Driver",
            messageText: "Your Driver Has Arrived at Pickup Location",
            chatRoomId: widget.ride['ID'].toString(),
          );
        } catch (e) {}

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          final updatedRide = Map<String, dynamic>.from(widget.ride);
          updatedRide['Status'] = 'arrived';

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

  Future<void> _startRide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.startRide(token, widget.ride['ID']);

      if (result['success'] == true) {
        setState(() {
          _isStarted = true;
          _sliderValue = 1.0;
        });

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
              'Ride started notification sent to passenger $passengerId',
            );
          } catch (e) {}
        }

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          final updatedRide = Map<String, dynamic>.from(widget.ride);
          updatedRide['Status'] = 'started';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.completeRide(token, widget.ride['ID']);

      if (result['success'] == true) {
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'completed';

        setState(() {
          _sliderValue = 1.0;
        });

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
              'Ride completed notification sent to passenger $passengerId',
            );
          } catch (e) {}
        }

        await Future.delayed(const Duration(milliseconds: 500));

        widget.onRideStatusChanged(updatedRide);
      } else {
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
      final rawRideId = widget.ride['ID'];
      final int? rideId = rawRideId is int
          ? rawRideId
          : int.tryParse(rawRideId?.toString() ?? '');

      if (rideId == null) {
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Invalid ride ID. Please try again.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = 'POINT(${position.longitude} ${position.latitude})';
      final locationAddress =
          'Lat: ${position.latitude}, Lng: ${position.longitude}';

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

      if (!mounted) return;
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

      if (!mounted) return;

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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.kWhiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: AppColors.kFailureColor,
                    size: 28.sp,
                  ),
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
                      color: AppColors.kFailureColor,
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
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.kWhiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: AppColors.kFailureColor, size: 28.sp),
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
                    color: AppColors.kFailureColor,
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
          side: BorderSide(color: AppColors.kMainColor, width: 2),
        ),
        backgroundColor: AppColors.kWhiteColor,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MuvamTexts.titleMedium18(
                context,
                text: 'Cancel Ride',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 20.h),
              MuvamTexts.bodyMedium14(
                context,
                text: 'Please provide a reason for cancellation:',
                isTextWidget: true,
                fontWeight: FontWeight.w400,
                color: AppColors.kBlackColor.withOpacity(0.87),
                center: true,
              ),
              SizedBox(height: 15.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter cancellation reason',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kGreyColor,
                    ),
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
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
                          color: AppColors.kWhiteColor,
                          border: Border.all(
                            color: AppColors.kMainColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: MuvamTexts.button16(
                            context,
                            text: 'Cancel',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kMainColor,
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
                          color: AppColors.kMainColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: MuvamTexts.button16(
                            context,
                            text: 'Submit',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kWhiteColor,
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
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: MuvamTexts.bodyMedium14(
                  context,
                  text:
                      'You are still very far to the pickup location to swipe to arrive. You have to be 1km near the pickup before you can swipe to arrive.',
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  center: true,
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 282.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.kMainColor,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Ok',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kWhiteColor,
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

    context.pop();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await ApiService.cancelRideWithReason(
        token,
        widget.ride['ID'],
        reason,
      );
      if (result['success'] == true) {
        final updatedRide = Map<String, dynamic>.from(widget.ride);
        updatedRide['Status'] = 'cancelled';
        widget.onRideStatusChanged(updatedRide);
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
