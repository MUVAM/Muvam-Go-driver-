import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RideItem extends StatelessWidget {
  final String location;
  final String time;
  final String amount;

  const RideItem({
    super.key,
    required this.location,
    required this.time,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        color: Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    height: 20 / 16,
                    letterSpacing: -0.08,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    height: 20 / 14,
                    letterSpacing: -0.08,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 20 / 16,
              letterSpacing: -0.08,
              color: Color(0xFF2A8359),
            ),
          ),
        ],
      ),
    );
  }
}
