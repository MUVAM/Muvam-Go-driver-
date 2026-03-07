import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class EarningsSectionWidget extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const EarningsSectionWidget({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 5.w),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.bodyMedium14(
                    context,
                    text: title,
                    color: AppColors.kHomeGreyColor,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  MuvamTexts.headlineMedium28(
                    context,
                    text: value,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              ConstImages.chevronBack,
              width: 20.w,
              height: 20.h,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(
                AppColors.kBlackColor,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
