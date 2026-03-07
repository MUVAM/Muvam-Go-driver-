import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class HowToWithdraw extends StatelessWidget {
  const HowToWithdraw({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 35.w,
                      height: 35.h,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: MuvamTexts.titleLarge22(
                        context,
                        text: 'Withdrawal',
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
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'How to withdraw',
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
                                'Once you reach the earning dashboard, click the withdrawal button on the earning card.',
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
                                'While you are at the withdrawal form screen, enter your correct details so as not to result in money loss.',
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
