import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

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
        return const Color(0xFFE53935);
      case 'tip':
        return const Color(0xFF1E88E5);
      case 'commission':
        return const Color(0xFFF57C00);
      case 'ride_earning':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF43A047);
    }
  }

  String _getSign() {
    return type == 'withdrawal' ? '-' : '+';
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final amountColor = _getAmountColor();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -0.32,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                dateTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: -0.2,
                  color: themeManager.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          Text(
            '${_getSign()}$formattedAmount',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
