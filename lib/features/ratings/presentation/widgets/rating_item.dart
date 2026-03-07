import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class RatingItem extends StatelessWidget {
  final String name;
  final int rating;
  final String time;
  final String comment;

  const RatingItem({
    super.key,
    required this.name,
    required this.rating,
    required this.time,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(ConstImages.avatar, width: 38.w, height: 38.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuvamTexts.bodyLarge16(
                  context,
                  text: name,
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Padding(
                          padding: EdgeInsets.only(right: index < 4 ? 2.w : 0),
                          child: Icon(
                            Icons.star,
                            size: 14.sp,
                            color: index < rating
                                ? Colors.amber
                                : AppColors.kGreyColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    MuvamTexts.bodySmall12(
                      context,
                      text: time,
                      isTextWidget: true,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: comment,
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: AppColors.kBlackColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
