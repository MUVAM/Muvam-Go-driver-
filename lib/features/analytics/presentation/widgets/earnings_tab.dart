import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/breakdown_item.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';

class EarningsTab extends StatelessWidget {
  final EarningsProvider earningsProvider;

  const EarningsTab({super.key, required this.earningsProvider});

  @override
  Widget build(BuildContext context) {
    final breakdown = earningsProvider.earningsBreakdown;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 110.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D6B4A), Color(0xFF0F3D25)],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),

              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  Positioned(
                    top: -30.h,
                    left: -30.w,
                    child: Container(
                      width: 110.w,
                      height: 110.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.kWhiteColor.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30.h,
                    right: -20.w,
                    child: Container(
                      width: 130.w,
                      height: 130.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.kWhiteColor.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MuvamTexts.bodyLarge16(
                            context,
                            text: 'Total earned',
                            isTextWidget: true,
                            fontWeight: FontWeight.w400,
                            center: false,
                            color: AppColors.kGreyColor.withOpacity(0.55),
                          ),
                          SizedBox(height: 8.h),
                          MuvamTexts.headlineLarge32(
                            context,
                            text: earningsProvider.formatPrice(
                              breakdown?.totalEarned ?? 0,
                            ),
                            isTextWidget: true,
                            fontWeight: FontWeight.w700,
                            center: false,
                            color: AppColors.kWhiteColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -30.h,
              left: -35.w,
              child: Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20.h,
              right: -10.w,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -15.h,
              right: 40.w,
              child: Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.w),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.kBlackColor.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuvamTexts.titleMedium18(
                context,
                text: 'Earning Breakdown',
                isTextWidget: true,
                fontWeight: FontWeight.w700,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 24.h),
              BreakdownItem(
                label: 'Gross earning',
                amount: earningsProvider.formatPrice(
                  breakdown?.grossEarning ?? 0,
                ),
                isTotal: false,
              ),
              SizedBox(height: 18.h),
              BreakdownItem(
                label: 'Tips received',
                amount: earningsProvider.formatPrice(
                  breakdown?.tipsReceived ?? 0,
                ),
                isTotal: false,
              ),
              SizedBox(height: 18.h),
              BreakdownItem(
                label: 'Platform fee',
                amount: earningsProvider.formatPrice(
                  breakdown?.platformFee ?? 0,
                ),
                isTotal: false,
              ),
              SizedBox(height: 18.h),
              const Divider(color: Color(0xFFE5E5E5), thickness: 1),
              SizedBox(height: 18.h),
              BreakdownItem(
                label: 'Platform fee',
                amount: earningsProvider.formatPrice(breakdown?.netPayout ?? 0),
                isTotal: true,
              ),
            ],
          ),
        ),
        DeviceBottomPadding(),
      ],
    );
  }
}
