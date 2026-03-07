import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final String displayText;
  final VoidCallback onTap;
  final Color? textColor;

  const DropdownField({
    super.key,
    required this.label,
    required this.displayText,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 353.w,
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.kFormFieldColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MuvamTexts.bodyMedium14(
                  context,
                  text: displayText,
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: textColor ?? AppColors.kGreyColor,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.kGreyColor,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
