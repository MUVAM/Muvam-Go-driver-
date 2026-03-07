import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';

class HistoryCompletedScreen extends StatefulWidget {
  final int rideId;

  const HistoryCompletedScreen({super.key, required this.rideId});

  @override
  State<HistoryCompletedScreen> createState() => _HistoryCompletedScreenState();
}

class _HistoryCompletedScreenState extends State<HistoryCompletedScreen> {
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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<RequestProvider>(
          builder: (context, provider, child) {
            final ride =
                provider.selectedRide ??
                provider.historyRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.historyRides.isNotEmpty
                      ? provider.historyRides.first
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
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Booking Id: ${ride.id}',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 12.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatTime(ride.createdAt),
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kBlackColor,
                  ),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatDate(ride.createdAt),
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 30.h),
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
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Pick Up',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kGreyColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: ride.pickupAddress,
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Row(
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
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: AppColors.kFailureColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Destination',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kGreyColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: ride.destAddress,
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'Payment method',
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kGreyColor,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.kGreyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.sp),
                          decoration: BoxDecoration(
                            color: AppColors.kWhiteColor,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MuvamTexts.bodySmall12(
                                context,
                                text: 'Amount',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kBlackColor,
                              ),
                              MuvamTexts.bodyMedium14(
                                context,
                                text: provider.formatPrice(ride.price),
                                isTextWidget: true,
                                fontWeight: FontWeight.w400,
                                color: AppColors.kBlackColor,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.sp),
                                  width: 50.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.kWhiteColor,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: SvgPicture.asset(
                                    ConstImages.cashCard,
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                MuvamTexts.bodyMedium14(
                                  context,
                                  text: ride.paymentMethod,
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.kBlackColor,
                                ),
                              ],
                            ),
                            MuvamTexts.bodyMedium14(
                              context,
                              text: provider.formatPrice(ride.price),
                              isTextWidget: true,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kMainColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Ride Status',
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kGreyColor,
                  ),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: ride.status,
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kMainColor,
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
