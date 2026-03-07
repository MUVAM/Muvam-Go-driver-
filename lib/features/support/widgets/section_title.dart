import 'package:flutter/material.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return MuvamTexts.titleMedium18(
      context,
      text: title,
      isTextWidget: true,
      fontWeight: FontWeight.w700,
      color: AppColors.kBlackColor,
    );
  }
}
