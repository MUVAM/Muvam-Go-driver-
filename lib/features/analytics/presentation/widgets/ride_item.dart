import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class RideItem extends StatelessWidget {
  final String location;
  final String time;
  final String amount;

  const RideItem({
    super.key,
    required this.location,
    required this.time,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        color: AppColors.kFormFieldColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuvamTexts.bodyMedium14(
                  context,
                  text: location,
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kBlackColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                MuvamTexts.bodySmall12(
                  context,
                  text: time,
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: AppColors.kBlackColor.withOpacity(0.54),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          MuvamTexts.bodyMedium14(
            context,
            text: amount,
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kMainColor,
          ),
        ],
      ),
    );
  }
}
