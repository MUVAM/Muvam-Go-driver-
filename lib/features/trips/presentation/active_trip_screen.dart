import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
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
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to open Google Maps',
      );
    }
  }

  String formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  String formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                          context.pop();
                        },
                        child: Icon(
                          Icons.arrow_back,
                          size: 24.sp,
                          color: AppColors.kBlackColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      MuvamTexts.headlineSmall24(
                        context,
                        text: 'Ongoing ride',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                      const Spacer(),
                      MuvamTexts.bodyMedium14(
                        context,
                        text: "Active",
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kMainColor,
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
                          color: AppColors.kMainColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Pick up',
                        isTextWidget: true,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.pickupAddress,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
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
                          color: AppColors.kFailureColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Destination',
                        isTextWidget: true,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.destAddress,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'When',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9E9E9E),
                  ),
                  SizedBox(height: 8.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MuvamTexts.bodyMedium14(
                            context,
                            text: formatTime(ride.createdAt),
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          MuvamTexts.bodyLarge16(
                            context,
                            text: formatDate(ride.createdAt),
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlackColor,
                          ),
                        ],
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
                                MuvamTexts.bodySmall12(
                                  context,
                                  text: 'Payment method',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                SizedBox(height: 8.h),
                                MuvamTexts.bodyLarge16(
                                  context,
                                  text: ride.paymentMethod,
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kBlackColor,
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
                                MuvamTexts.bodySmall12(
                                  context,
                                  text: 'Vehicle',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                SizedBox(height: 8.h),
                                MuvamTexts.bodyLarge16(
                                  context,
                                  text: ride.vehicleType,
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kBlackColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      SizedBox(height: 10.h),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: 'Price',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9E9E9E),
                      ),
                      SizedBox(height: 8.h),
                      MuvamTexts.headlineSmall24(
                        context,
                        text: provider.formatPrice(ride.price),
                        isTextWidget: true,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kBlackColor,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openGoogleMaps,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'View in map',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kWhiteColor,
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
