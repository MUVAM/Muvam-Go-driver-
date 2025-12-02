import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/fonts.dart';
import '../constants/theme_manager.dart';
import 'onboarding_screen.dart';

class RiderSignupSelectionScreen extends StatefulWidget {
  const RiderSignupSelectionScreen({super.key});

  @override
  State<RiderSignupSelectionScreen> createState() => _RiderSignupSelectionScreenState();
}

class _RiderSignupSelectionScreenState extends State<RiderSignupSelectionScreen> {
  Set<int> selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              Text(
                'How do you want to sign up',
                style: TextStyle(
                  fontFamily: ConstFonts.inter,
                  fontWeight: FontWeight.w600,
                  fontSize: 26.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'You can select more than one service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: ConstFonts.inter,
                  fontWeight: FontWeight.w400,
                  fontSize: 16.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 40.h),
              Center(
                child: Column(
                  children: [
                    _buildServiceOption(
                      index: 0,
                      title: 'Taxi Driver',
                      imagePath: 'assets/images/driversignup.png',
                    ),
                    SizedBox(height: 24.h),
                    _buildServiceOption(
                      index: 1,
                      title: 'Delivery Rider',
                      imagePath: 'assets/images/deliverysignup.png',
                    ),
                  ],
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedOptions.isNotEmpty
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: GestureDetector(
                    onTap: selectedOptions.isNotEmpty ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                      );
                    } : null,
                    child: Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceOption({
    required int index,
    required String title,
    required String imagePath,
  }) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isSelected = selectedOptions.contains(index);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedOptions.contains(index)) {
            selectedOptions.remove(index);
          } else {
            selectedOptions.add(index);
          }
        });
      },
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
              border: Border.all(
                color: Color(0xFFB1B1B1),
                width: 1,
              ),
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
                      decoration: BoxDecoration(
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