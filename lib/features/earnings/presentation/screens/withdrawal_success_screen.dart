import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';

class WithdrawalSuccessScreen extends StatelessWidget {
  final double amount;

  const WithdrawalSuccessScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
            MuvamTexts.headlineSmall24(
              context,
              text: 'Withdrawal Successful',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
              center: true,
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: MuvamTexts.bodyLarge16(
                context,
                text:
                    'Your withdrawal of ₦${amount.toStringAsFixed(0)} is successful you will receive the withdrawal in 30mins.',
                isTextWidget: true,
                fontWeight: FontWeight.w400,
                color: AppColors.kBlackColor,
                center: true,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.goNamed(AppRoutes.home.name);
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
                          text: 'Go back home',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  MuvamTexts.button16(
                    context,
                    text: 'View transaction history',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kMainColor,
                    center: true,
                  ),
                ],
              ),
            ),
            DeviceBottomPadding(),
          ],
        ),
      ),
    );
  }
}
