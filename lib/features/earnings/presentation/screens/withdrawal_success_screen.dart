import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WithdrawalSuccessScreen extends StatelessWidget {
  const WithdrawalSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 105.h),
            Container(
              width: 400.w,
              height: 400.h,
              child: Image.asset(
                'assets/images/withdraw_success.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Withdrawal Successful',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                height: 21 / 24,
                letterSpacing: -0.32,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Your withdrawal of ₦45,000 is successful you will receive the withdrawal in 30mins.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 16.sp,
                  height: 21 / 16,
                  letterSpacing: -0.32,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Color(0xFF2A8359),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Go back home',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'View transaction history',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      height: 21 / 24,
                      letterSpacing: -0.32,
                      color: Color(0xFF2A8359),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
