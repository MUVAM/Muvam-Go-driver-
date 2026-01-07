import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';

class CarItem extends StatelessWidget {
  final String carName;
  final String year;

  const CarItem({super.key, required this.carName, required this.year});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      child: Row(
        children: [
          Image.asset(ConstImages.car, width: 40.w, height: 40.h),
          SizedBox(width: 15.w),
          Expanded(
            child: Text(
              '$carName $year',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CarInformationScreen()),
              );
            },
            child: Text(
              'Edit',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFBDBDBD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
