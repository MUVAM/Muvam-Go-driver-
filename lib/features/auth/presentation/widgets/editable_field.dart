import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditable;
  final VoidCallback onEditTap;

  const EditableField({
    super.key,
    required this.label,
    required this.controller,
    required this.isEditable,
    required this.onEditTap,
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
          fontWeight: FontWeight.w400,
          color: AppColors.kGreyColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: AppColors.kFormFieldColor,
            borderRadius: BorderRadius.circular(3.r),
          ),
          padding: EdgeInsets.only(
            top: 15.h,
            right: 14.w,
            bottom: 15.h,
            left: 14.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    enabled: isEditable,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: MuvamTexts.bodyMedium14(
                  context,
                  text: 'Edit',
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: AppColors.kMainColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
