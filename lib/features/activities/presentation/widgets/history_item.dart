import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class HistoryItem extends StatelessWidget {
  final String time;
  final String date;
  final String destination;
  final bool isCompleted;
  final String? price;
  final VoidCallback onTap;

  const HistoryItem({
    super.key,
    required this.time,
    required this.date,
    required this.destination,
    required this.isCompleted,
    required this.onTap,
    this.price,
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
                isCompleted
                    ? MuvamTexts.bodyMedium14(
                        context,
                        text: price ?? '',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      )
                    : Container(
                        width: 70.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.kFailureColor,
                            width: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        padding: EdgeInsets.only(
                          top: 2.h,
                          right: 7.w,
                          bottom: 2.h,
                          left: 7.w,
                        ),
                        child: Center(
                          child: MuvamTexts.bodyMedium14(
                            context,
                            text: 'Cancelled',
                            isTextWidget: true,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kFailureColor,
                          ),
                        ),
                      ),
              ],
            ),
            SizedBox(height: 15.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
