import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class TripCard extends StatelessWidget {
  final String time;
  final String date;
  final String destination;
  final String tripId;
  final VoidCallback onTap;
  final bool isActive;

  const TripCard({
    super.key,
    required this.time,
    required this.date,
    required this.destination,
    required this.tripId,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: AppColors.kGreyColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        padding: EdgeInsets.all(15.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuvamTexts.bodySmall12(
                      context,
                      text: time,
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kBlackColor,
                    ),
                    MuvamTexts.bodyLarge16(
                      context,
                      text: date,
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlackColor,
                    ),
                  ],
                ),
                if (isActive) ...[
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.kSuccessColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Trip ID',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kBlackColor,
                      ),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: tripId,
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            SizedBox(height: 15.h),
            MuvamTexts.bodySmall12(
              context,
              text: 'Destination',
              isTextWidget: true,
              fontWeight: FontWeight.w500,
              color: AppColors.kBlackColor,
            ),
            SizedBox(height: 5.h),
            MuvamTexts.bodyMedium14(
              context,
              text: destination,
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
          ],
        ),
      ),
    );
  }
}
