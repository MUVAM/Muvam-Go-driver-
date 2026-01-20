import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final String displayText;
  final VoidCallback onTap;
  final Color? textColor;

  const DropdownField({
    super.key,
    required this.label,
    required this.displayText,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 353.w,
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Color(ConstColors.formFieldColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: textColor ?? Colors.grey.shade400,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
