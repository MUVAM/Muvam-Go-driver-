import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreakdownItem extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const BreakdownItem({
    super.key,
    required this.label,
    required this.amount,
    required this.isTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            fontSize: isTotal ? 18.sp : 16.sp,
            color: isTotal ? Colors.black : Color(0xFF666666),
            letterSpacing: -0.3,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            fontSize: isTotal ? 18.sp : 16.sp,
            color: isTotal ? Color(0xFF2A8359) : Colors.black,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
