import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class ContinueButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const ContinueButton({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.kMainColor : AppColors.kGreyColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: AppColors.kWhiteColor,
                    strokeWidth: 2,
                  ),
                )
              : MuvamTexts.button16(
                  context,
                  text: 'Continue',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kWhiteColor,
                ),
        ),
      ),
    );
  }
}
