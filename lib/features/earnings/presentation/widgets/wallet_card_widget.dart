import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';

class WalletCardWidget extends StatelessWidget {
  final dynamic walletSummary;
  final WalletProvider walletProvider;

  const WalletCardWidget({
    super.key,
    required this.walletSummary,
    required this.walletProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 160.h,
          decoration: BoxDecoration(
            color: AppColors.kBlackColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MuvamTexts.bodyMedium14(
                      context,
                      text: 'Your balance',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kWhiteColor,
                    ),
                    Container(
                      width: 100.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: AppColors.kWhiteColor,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            context.pushNamed(AppRoutes.withdrawal.name),
                        child: Center(
                          child: MuvamTexts.bodyMedium14(
                            context,
                            text: 'Withdraw',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MuvamTexts.headlineSmall24(
                    context,
                    text: walletProvider.formatAmount(walletSummary.balance),
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                    color: AppColors.kWhiteColor,
                  ),
                ),
                const Spacer(),
                MuvamTexts.bodyMedium14(
                  context,
                  text: 'Pending balance',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kWhiteColor,
                ),
                SizedBox(height: 4.h),
                MuvamTexts.headlineSmall24(
                  context,
                  text: walletProvider.formatAmount(
                    walletSummary.pendingBalance,
                  ),
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: AppColors.kWhiteColor,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -54.h,
          left: -43.w,
          child: Container(
            width: 103.w,
            height: 103.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 99.h,
          left: 237.w,
          child: Container(
            width: 79.w,
            height: 79.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 89.h,
          left: 297.w,
          child: Container(
            width: 79.w,
            height: 79.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
