import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';

class AccountVerificationSuccessScreen extends StatelessWidget {
  const AccountVerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/success.png',
                width: 208.w,
                height: 208.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40.h),
              MuvamTexts.headlineSmall24(
                context,
                text: 'Verification Successful',
                isTextWidget: true,
                center: true,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: MuvamTexts.bodyMedium14(
                  context,
                  text:
                      'We\'ve confirmed your information and your account is now fully active. You\'re ready to start driving and earning with confidence.',
                  isTextWidget: true,
                  center: true,
                  color: AppColors.kSubtitleColor,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.pushReplacementNamed(AppRoutes.carInformation.name);
                },
                child: Container(
                  width: double.infinity,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: AppColors.kMainColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Continue',
                      color: AppColors.kWhiteColor,
                      fontWeight: FontWeight.w600,
                      isTextWidget: true,
                    ),
                  ),
                ),
              ),
              DeviceBottomPadding(),
            ],
          ),
        ),
      ),
    );
  }
}
