import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';

class BankSelectorWidget extends StatelessWidget {
  const BankSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WithdrawalProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: 'Bank name',
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: provider.isLoading
              ? null
              : () {
                  context.pushNamed(AppRoutes.bankSelection.name);
                },
          child: Container(
            width: double.infinity,
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            decoration: BoxDecoration(
              color: AppColors.kFieldColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: provider.isLoading
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              color: AppColors.kBlackColor,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : MuvamTexts.bodyMedium14(
                          context,
                          text:
                              provider.selectedBank?.name ?? 'Select your bank',
                          isTextWidget: true,
                          fontSize: provider.selectedBank != null
                              ? 14.sp
                              : 12.sp,
                          color: provider.selectedBank != null
                              ? AppColors.kBlackColor
                              : AppColors.kGreyColor,
                        ),
                ),
                SvgPicture.asset(
                  ConstImages.dropDownIcon,
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.scaleDown,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
