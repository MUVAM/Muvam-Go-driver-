import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class BreakdownItem extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const BreakdownItem({
    super.key,
    required this.label,
    required this.amount,
    required this.isTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
          fontSize: isTotal ? 18.sp : 16.sp,
          color: isTotal ? AppColors.kBlackColor : const Color(0xFF666666),
        ),
        MuvamTexts.bodyLarge16(
          context,
          text: amount,
          isTextWidget: true,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          fontSize: isTotal ? 18.sp : 16.sp,
          color: isTotal ? AppColors.kMainColor : AppColors.kBlackColor,
        ),
      ],
    );
  }
}
