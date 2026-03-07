import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class VerificationTileWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isActionable;
  final bool isVerified;

  const VerificationTileWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isActionable = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 5.h),
              child: Image.asset(
                height: 16.h,
                width: 16.w,
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.description,
                    color: AppColors.kMainColor,
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.bodyLarge16(
                    context,
                    text: title,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 4.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text: subtitle,
                    isTextWidget: true,
                    color: AppColors.kSubtitleColor,
                    height: 1.4,
                  ),
                ],
              ),
            ),
            if (isVerified)
              Padding(
                padding: EdgeInsets.only(left: 8.w, top: 10.h),
                child: Icon(
                  Icons.check_circle,
                  size: 20.sp,
                  color: Colors.green,
                ),
              )
            else if (isActionable)
              Padding(
                padding: EdgeInsets.only(left: 8.w, top: 30.h),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppColors.kBlackColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
