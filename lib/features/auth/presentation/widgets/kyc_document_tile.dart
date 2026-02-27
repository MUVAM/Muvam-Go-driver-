import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

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
        decoration: BoxDecoration(border: Border()),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              icon,
              width: 24.w,
              height: 24.h,
              color: isUploaded
                  ? themeManager.getTextColor(context)
                  : Colors.black,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: ConstFonts.inter,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: isUploaded
                          ? themeManager.getTextColor(context)
                          : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: ConstFonts.inter,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                            height: 1.5,
                            color: isUploaded
                                ? themeManager.getTextColor(context)
                                : Color(0xFF808080),
                          ),
                        ),
                      ),
                      // SizedBox(width: 12.w),
                      isUploaded
                          ? Icon(
                              Icons.check_circle,
                              size: 16.sp,
                              color: Color(0xff2A8359),
                            )
                          : SvgPicture.asset(
                              ConstImages.backChevron,
                              color: isUploaded
                                  ? themeManager.getTextColor(context)
                                  : Color(0xFF808080),
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
