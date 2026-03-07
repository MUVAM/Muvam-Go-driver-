import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool enabled;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hintText = '',
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: 45.h,
          decoration: BoxDecoration(
            color: AppColors.kFieldColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(15.w),
              hintText: hintText.isNotEmpty ? hintText : 'Enter $label',
              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.kGreyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
