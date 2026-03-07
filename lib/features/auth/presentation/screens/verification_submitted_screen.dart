import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class VerificationSubmittedScreen extends StatelessWidget {
  const VerificationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AppScaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              MuvamTexts.headlineSmall24(
                context,
                text: 'Verification Submitted!',
                isTextWidget: true,
                center: true,
                color: themeManager.getTextColor(context),
              ),
              SizedBox(height: 12.h),
              MuvamTexts.bodyMedium14(
                context,
                text:
                    'Your vehicle verification documents have been submitted successfully. We will review your documents and get back to you soon.',
                isTextWidget: true,
                center: true,
                color: themeManager.getSecondaryTextColor(context),
              ),
              SizedBox(height: 40.h),
              GestureDetector(
                onTap: () {
                  context.goNamedRoute(AppRoutes.home.name);
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
