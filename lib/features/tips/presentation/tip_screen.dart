import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final List<dynamic> tipAmounts = [0, 500, 1000, 1500, 2000, 'Custom'];
  int? selectedTip;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Positioned(
                  top: 70.h,
                  left: 20.w,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45.w,
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: AppColors.kWhiteColor,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Image.asset(ConstImages.back, fit: BoxFit.contain),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                MuvamTexts.headlineSmall24(
                  context,
                  text: 'Automatically add a tip to all trips',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 20.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: 'Choose an amount',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 30.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                  ),
                  itemCount: tipAmounts.length,
                  itemBuilder: (context, index) {
                    final amount = tipAmounts[index];
                    final isSelected = selectedTip == amount;
                    final isCustom = amount == 'Custom';

                    return GestureDetector(
                      onTap: () {
                        if (isCustom) {
                          context.pushNamed('customTip');
                        } else {
                          setState(() {
                            selectedTip = amount;
                          });
                        }
                      },
                      child: Container(
                        width: 170.w,
                        height: 170.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.kMainColor
                              : AppColors.kFieldColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: isCustom
                              ? MuvamTexts.titleMedium18(
                                  context,
                                  text: 'Custom',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.kWhiteColor
                                      : AppColors.kBlackColor,
                                )
                              : MuvamTexts.titleMedium18(
                                  context,
                                  text: '₦$amount',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.kWhiteColor
                                      : AppColors.kBlackColor,
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedTip != null
                        ? AppColors.kMainColor
                        : AppColors.kGreyColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Save tip',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
