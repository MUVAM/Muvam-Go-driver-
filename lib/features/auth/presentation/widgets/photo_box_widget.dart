import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/dashed_border_painter.dart';

class PhotoBoxWidget extends StatelessWidget {
  final File? photo;
  final int index;
  final ThemeManager themeManager;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const PhotoBoxWidget({
    super.key,
    required this.photo,
    required this.index,
    required this.themeManager,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: Colors.grey.shade400,
          strokeWidth: 2,
          gap: 6,
          radius: 8.r,
        ),
        child: Container(
          width: 102.w,
          height: 102.w,
          child: photo != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.file(
                        photo!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.kError,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.kWhiteColor,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    Icons.add,
                    size: 40.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
        ),
      ),
    );
  }
}
