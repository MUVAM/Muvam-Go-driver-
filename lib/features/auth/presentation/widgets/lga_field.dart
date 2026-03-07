import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

class LgaField extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedState;
  final String? selectedLga;
  final Function(String) onLgaSelected;
  final ThemeManager themeManager;

  const LgaField({
    super.key,
    required this.controller,
    required this.selectedState,
    required this.selectedLga,
    required this.onLgaSelected,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: 'LGA',
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: selectedState == null
              ? null
              : () async {
                  final result = await context.pushNamed(
                    'lgaSelection',
                    extra: {'selectedState': selectedState},
                  );
                  if (result != null) {
                    onLgaSelected(result as String);
                    controller.text = result as String;
                  }
                },
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: selectedState == null
                  ? Colors.grey.shade200
                  : AppColors.kLocationFieldColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MuvamTexts.bodyLarge16(
                    context,
                    text: controller.text.isEmpty
                        ? (selectedState == null
                              ? 'Select State first'
                              : 'Select LGA')
                        : controller.text,
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: controller.text.isEmpty
                        ? AppColors.kGreyColor
                        : AppColors.kBlackColor,
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 5.w,
                    height: 5.h,
                    fit: BoxFit.contain,
                    colorFilter: selectedState == null
                        ? ColorFilter.mode(
                            AppColors.kGreyColor,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
