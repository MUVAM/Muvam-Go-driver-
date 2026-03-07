import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';

class DocumentVerificationSuccessScreen extends StatelessWidget {
  const DocumentVerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
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
                text: 'Verification Submitted',
                isTextWidget: true,
                center: true,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
                child: MuvamTexts.bodyMedium14(
                  context,
                  text:
                      'We\'ve received your documents and they are now under review. You will receive a notification in 30mins.',
                  isTextWidget: true,
                  center: true,
                  color: AppColors.kSubtitleColor,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.goNamedRoute(AppRoutes.home.name);
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
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
