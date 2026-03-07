import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class VehicleOptionWidget extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final String price;
  final int? selectedVehicle;
  final VoidCallback onTap;

  const VehicleOptionWidget({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selectedVehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedVehicle == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 353.w,
        height: 65.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kMainColor : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.kMainColor
                : AppColors.kGreyColor.withOpacity(0.3),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Image.asset(ConstImages.car, width: 55.w, height: 26.h),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MuvamTexts.titleMedium18(
                    context,
                    text: title,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.kWhiteColor
                        : AppColors.kBlackColor,
                  ),
                  MuvamTexts.bodySmall12(
                    context,
                    text: subtitle,
                    color: isSelected
                        ? AppColors.kWhiteColor
                        : AppColors.kBlackColor,
                  ),
                ],
              ),
            ),
            MuvamTexts.titleMedium18(
              context,
              text: price,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.kWhiteColor : AppColors.kBlackColor,
            ),
          ],
        ),
      ),
    );
  }
}
