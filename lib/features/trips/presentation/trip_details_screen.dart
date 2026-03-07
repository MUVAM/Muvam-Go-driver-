import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:provider/provider.dart';

class TripDetailsScreen extends StatefulWidget {
  final int rideId;

  const TripDetailsScreen({super.key, required this.rideId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RequestProvider>();
      if (provider.selectedRide?.id != widget.rideId) {
        provider.fetchRideDetails(widget.rideId);
      }
    });
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<RequestProvider>(
          builder: (context, provider, child) {
            final ride =
                provider.selectedRide ??
                provider.prebookedRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.prebookedRides.isNotEmpty
                      ? provider.prebookedRides.first
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
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Order details',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
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
                  Row(
                    children: [
                      MuvamTexts.titleMedium18(
                        context,
                        text: _formatDate(ride.createdAt),
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kBlackColor,
                      ),
                      const SizedBox(width: 5),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: _formatTime(ride.createdAt),
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
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
            );
          },
        ),
      ),
    );
  }
}
