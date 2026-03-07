import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class MainTab extends StatelessWidget {
  final String text;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  const MainTab({
    super.key,
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 38.h,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.kMainColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Center(
            child: MuvamTexts.bodyLarge16(
              context,
              text: text,
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.kWhiteColor : AppColors.kGreyColor,
            ),
          ),
        ),
      ),
    );
  }
}
