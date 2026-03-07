import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';

class CarItem extends StatelessWidget {
  final String carName;
  final String year;

  const CarItem({super.key, required this.carName, required this.year});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      child: Row(
        children: [
          Image.asset(ConstImages.car, width: 40.w, height: 40.h),
          SizedBox(width: 15.w),
          Expanded(
            child: MuvamTexts.bodyLarge16(
              context,
              text: '$carName $year',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.pushNamed(AppRoutes.carInformation.name);
            },
            child: MuvamTexts.bodyMedium14(
              context,
              text: 'Edit',
              isTextWidget: true,
              fontWeight: FontWeight.w500,
              color: AppColors.kDrawerAccountColor,
            ),
          ),
        ],
      ),
    );
  }
}
