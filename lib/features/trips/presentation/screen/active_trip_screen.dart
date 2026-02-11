import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripScreen extends StatefulWidget {
  final int rideId;

  const ActiveTripScreen({super.key, required this.rideId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<RequestProvider>();
    final existingRide = provider.activeRides.firstWhere(
      (ride) => ride.id == widget.rideId,
      orElse: () => provider.activeRides.first,
    );

    if (existingRide.id == widget.rideId) {
      provider.clearSelectedRide();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchRideDetails(widget.rideId);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchRideDetails(widget.rideId);
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    try {
      final provider = context.read<RequestProvider>();
      final ride = provider.selectedRide;

      if (ride == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Ride details not available',
        );
        return;
      }

      String? destinationAddress;

      if (ride.status == 'started') {
        destinationAddress = ride.destAddress;
      } else {
        destinationAddress = ride.pickupAddress;
      }

      if (destinationAddress.isEmpty) {
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
      AppLogger.log('Error opening Google Maps: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to open Google Maps',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<RequestProvider>(
          builder: (context, provider, child) {
            final ride =
                provider.selectedRide ??
                provider.activeRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.activeRides.isNotEmpty
                      ? provider.activeRides.first
                      : null as dynamic,
                );

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          provider.clearSelectedRide();
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back,
                          size: 24.sp,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Text(
                        'Ongoing ride',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Active",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Color(ConstColors.mainColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Pick up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    ride.pickupAddress,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      SvgPicture.asset(
                        ConstImages.lineArrow,
                        width: 24.w,
                        height: 24.h,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    ride.destAddress,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'When',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.formatDateTime(ride.scheduledAt ?? ride.createdAt),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment method',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              ride.paymentMethod,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              ride.vehicleType,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  Text(
                    'Price',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.formatPrice(ride.price),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: _openGoogleMaps,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'View in map',
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
            );
          },
        ),
      ),
    );
  }
}
