import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

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
    final themeManager = Provider.of<ThemeManager>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            color: themeManager.getTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: 45.h,
          decoration: BoxDecoration(
            color: const Color(ConstColors.fieldColor).withOpacity(0.12),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              color: themeManager.getTextColor(context),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(15.w),
              hintText: hintText.isNotEmpty ? hintText : 'Enter $label',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
