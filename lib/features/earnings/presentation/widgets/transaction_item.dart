import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

class TransactionItem extends StatelessWidget {
  final String amount;
  final String dateTime;
  final String status;
  final Color statusColor;

  const TransactionItem({
    super.key,
    required this.amount,
    required this.dateTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                dateTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: themeManager.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
