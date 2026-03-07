import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class CancelReasonWidget extends StatelessWidget {
  final int index;
  final String reason;
  final int? selectedCancelReason;
  final Function(int) onReasonSelected;

  const CancelReasonWidget({
    super.key,
    required this.index,
    required this.reason,
    required this.selectedCancelReason,
    required this.onReasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCancelReason == index;
    return GestureDetector(
      onTap: () => onReasonSelected(index),
      child: Container(
        width: 353.w,
        height: 40.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kMainColor : AppColors.kWhiteColor,
          border: Border.all(color: AppColors.kMainColor),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: MuvamTexts.bodyMedium14(
            context,
            text: reason,
            color: isSelected ? AppColors.kWhiteColor : AppColors.kBlackColor,
          ),
        ),
      ),
    );
  }
}
