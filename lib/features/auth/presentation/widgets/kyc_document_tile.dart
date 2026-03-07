import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';

class KycDocumentTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onTap;
  final ThemeManager themeManager;

  const KycDocumentTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onTap,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: const BoxDecoration(border: Border()),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              icon,
              width: 24.w,
              height: 24.h,
              color: isUploaded
                  ? themeManager.getTextColor(context)
                  : AppColors.kBlackColor,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.bodyLarge16(
                    context,
                    text: title,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: isUploaded
                        ? themeManager.getTextColor(context)
                        : AppColors.kBlackColor,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: MuvamTexts.bodyMedium14(
                          context,
                          text: subtitle,
                          isTextWidget: true,
                          fontWeight: FontWeight.w400,
                          color: isUploaded
                              ? themeManager.getTextColor(context)
                              : AppColors.kGreyColor,
                        ),
                      ),
                      isUploaded
                          ? Icon(
                              Icons.check_circle,
                              size: 24.sp,
                              color: AppColors.kSuccessColor,
                            )
                          : SvgPicture.asset(
                              ConstImages.backChevron,
                              color: isUploaded
                                  ? themeManager.getTextColor(context)
                                  : AppColors.kGreyColor,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
