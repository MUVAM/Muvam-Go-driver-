import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final Color valueColor;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MuvamTexts.titleLarge22(
            context,
            text: value,
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          SizedBox(height: 5.h),
          MuvamTexts.bodySmall12(
            context,
            text: label,
            isTextWidget: true,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5B5B5B),
          ),
        ],
      ),
    );
  }
}
