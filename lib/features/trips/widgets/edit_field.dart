import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class EditField extends StatelessWidget {
  final String label;
  final String value;

  const EditField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodySmall12(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.kFieldColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: MuvamTexts.bodyMedium14(
              context,
              text: value,
              isTextWidget: true,
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
            ),
          ),
        ),
      ],
    );
  }
}
