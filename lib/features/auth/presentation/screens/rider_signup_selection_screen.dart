import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/service_option.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

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
    return AppScaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              MuvamTexts.headlineSmall24(
                context,
                text: 'How do you want to sign up',
                isTextWidget: true,
                color: themeManager.getTextColor(context),
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 16.h),
              MuvamTexts.bodyLarge16(
                context,
                text: 'You can select more than one service',
                isTextWidget: true,
                color: themeManager.getTextColor(context),
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
              const Spacer(),
              GestureDetector(
                onTap: selectedOptions.isNotEmpty
                    ? () {
                        context.pushNamedRoute(AppRoutes.onboarding.name);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: selectedOptions.isNotEmpty
                        ? AppColors.kMainColor
                        : AppColors.kFieldColor,
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
