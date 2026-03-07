import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class ReferralRulesScreen extends StatelessWidget {
  const ReferralRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacings.k20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'Referral',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
              SizedBox(height: 40.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'How to get',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kMainColor,
                        center: true,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: AppColors.kMainColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: MuvamTexts.bodySmall12(
                              context,
                              text: '1',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWhiteColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: MuvamTexts.bodySmall12(
                            context,
                            text:
                                'Once your friend download the app, register with your referral code you get qualified for the reward',
                            isTextWidget: true,
                            fontWeight: FontWeight.w400,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: AppColors.kMainColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: MuvamTexts.bodySmall12(
                              context,
                              text: '2',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWhiteColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: MuvamTexts.bodySmall12(
                            context,
                            text:
                                'Once your friend placed a ride order, then you will be eligible for the 3days free ride',
                            isTextWidget: true,
                            fontWeight: FontWeight.w400,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
