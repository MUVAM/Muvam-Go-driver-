import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

class VerificationSubmittedScreen extends StatelessWidget {
  const VerificationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 80.sp,
                    color: Colors.green,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              Text(
                'Verification Submitted!',
                style: TextStyle(
                  fontFamily: ConstFonts.inter,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                  color: themeManager.getTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Your vehicle verification documents have been submitted successfully. We will review your documents and get back to you soon.',
                style: TextStyle(
                  fontFamily: ConstFonts.inter,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  color: themeManager.getSecondaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              GestureDetector(
                onTap: () {
                  // Navigate to home or dashboard
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: ConstFonts.inter,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
