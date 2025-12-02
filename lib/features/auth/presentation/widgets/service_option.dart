import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

class ServiceOption extends StatelessWidget {
  final int index;
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceOption({
    super.key,
    required this.index,
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 215.w,
            height: 185.h,
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(ConstColors.mainColor).withOpacity(0.2)
                  : themeManager.getCardColor(context),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFB1B1B1), width: 1),
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 3.75.h,
                    left: 3.75.w,
                    child: Container(
                      width: 22.5.w,
                      height: 22.5.h,
                      decoration: const BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                Positioned(
                  top: 19.h,
                  left: 12.w,
                  child: Image.asset(
                    imagePath,
                    width: 192.36.w,
                    height: 147.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: ConstFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 22.sp,
              height: 1.0,
              letterSpacing: -0.32,
              color: themeManager.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
