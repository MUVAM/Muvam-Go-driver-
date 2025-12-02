import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/service_option.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/auth/presentation/screens/onboarding_screen.dart';

class RiderSignupSelectionScreen extends StatefulWidget {
  const RiderSignupSelectionScreen({super.key});

  @override
  State<RiderSignupSelectionScreen> createState() =>
      _RiderSignupSelectionScreenState();
}

class _RiderSignupSelectionScreenState
    extends State<RiderSignupSelectionScreen> {
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
                    ServiceOption(
                      index: 0,
                      title: 'Taxi Driver',
                      imagePath: 'assets/images/driversignup.png',
                      isSelected: selectedOptions.contains(0),
                      onTap: () => _toggleOption(0),
                    ),
                    SizedBox(height: 24.h),
                    ServiceOption(
                      index: 1,
                      title: 'Delivery Rider',
                      imagePath: 'assets/images/deliverysignup.png',
                      isSelected: selectedOptions.contains(1),
                      onTap: () => _toggleOption(1),
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
                    onTap: selectedOptions.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen(),
                              ),
                            );
                          }
                        : null,
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

  void _toggleOption(int index) {
    setState(() {
      if (selectedOptions.contains(index)) {
        selectedOptions.remove(index);
      } else {
        selectedOptions.add(index);
      }
    });
  }
}
