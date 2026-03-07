import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasEdit;
  final VoidCallback? onTap;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.hasEdit = false,
    this.onTap,
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
          fontWeight: FontWeight.w400,
          color: AppColors.kGreyColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: AppColors.kFormFieldColor,
            borderRadius: BorderRadius.circular(3.r),
          ),
          padding: EdgeInsets.only(
            top: 15.h,
            right: 14.w,
            bottom: 15.h,
            left: 14.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MuvamTexts.bodyLarge16(
                context,
                text: value,
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
              if (hasEdit)
                GestureDetector(
                  onTap: onTap,
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: 'Edit',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kMainColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
