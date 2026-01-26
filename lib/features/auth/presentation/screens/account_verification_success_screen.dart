import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';

class AccountVerificationSuccessScreen extends StatelessWidget {
  const AccountVerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Image
              Image.asset(
                'assets/images/success.png',
                width: 208.w,
                height: 208.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40.h),
              // Title
              Text(
                'Verification Successful',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'We\'ve confirmed your information and your account is now fully active. You\'re ready to start driving and earning with confidence.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Continue Button
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CarInformationScreen(),
                    ),
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
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
