import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class ReasonItem extends StatelessWidget {
  final String reason;
  final bool isSelected;
  final VoidCallback onTap;

  const ReasonItem({
    super.key,
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 15.h),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppColors.kMainColor
                      : AppColors.kGreyColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.sp, color: AppColors.kMainColor)
                  : null,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: MuvamTexts.bodyLarge16(
                context,
                text: reason,
                isTextWidget: true,
                fontWeight: FontWeight.w400,
                color: AppColors.kBlackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
