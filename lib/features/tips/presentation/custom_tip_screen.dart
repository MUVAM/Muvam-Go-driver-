import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class CustomTipScreen extends StatefulWidget {
  const CustomTipScreen({super.key});

  @override
  State<CustomTipScreen> createState() => _CustomTipScreenState();
}

class _CustomTipScreenState extends State<CustomTipScreen> {
  final TextEditingController customTipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                padding: EdgeInsets.all(10.w),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(ConstImages.back, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 30.h),
              MuvamTexts.headlineSmall24(
                context,
                text: 'Choose a custom tip',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 40.h),
              Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: customTipController,
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kGreyColor,
                    ),
                    prefixText: '₦ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              SizedBox(height: 40.h),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: customTipController.text.isNotEmpty
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
            ],
          ),
        ),
      ),
    );
  }
}
