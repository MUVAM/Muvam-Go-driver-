import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class DetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isStop;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isStop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isStop ? Colors.yellow.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isStop)
                Icon(Icons.location_on, size: 16.sp, color: Colors.orange),
              if (isStop) SizedBox(width: 5.w),
              MuvamTexts.bodySmall12(
                context,
                text: label,
                fontWeight: FontWeight.w500,
                color: isStop ? Colors.orange : AppColors.kSubtitleColor,
              ),
            ],
          ),
          SizedBox(height: 5.h),
          MuvamTexts.titleSmall14(
            context,
            text: value,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
        ],
      ),
    );
  }
}
