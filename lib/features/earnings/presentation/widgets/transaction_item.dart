import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class TransactionItem extends StatelessWidget {
  final String description;
  final String dateTime;
  final String formattedAmount;
  final String type;

  const TransactionItem({
    super.key,
    required this.description,
    required this.dateTime,
    required this.formattedAmount,
    required this.type,
  });

  Color _getAmountColor() {
    switch (type) {
      case 'withdrawal':
        return AppColors.kFailureColor;
      case 'tip':
        return const Color(0xFF1E88E5);
      case 'commission':
        return const Color(0xFFF57C00);
      case 'ride_earning':
        return AppColors.kSuccessColor;
      default:
        return AppColors.kSuccessColor;
    }
  }

  String _getSign() {
    return type == 'withdrawal' ? '-' : '+';
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _getAmountColor();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuvamTexts.bodyMedium14(
                context,
                text: description,
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 2.h),
              MuvamTexts.bodyMedium14(
                context,
                text: dateTime,
                isTextWidget: true,
                fontWeight: FontWeight.w400,
                color: AppColors.kGreyColor,
              ),
            ],
          ),
          MuvamTexts.bodyMedium14(
            context,
            text: '${_getSign()}$formattedAmount',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ],
      ),
    );
  }
}
