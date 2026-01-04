import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/vehicles/presentation/widgets/car_item.dart';

class MyCarsScreen extends StatelessWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 30.w,
                      height: 30.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'My cars',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    CarItem(carName: 'Toyota Camry', year: '2020'),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    CarItem(carName: 'Honda Accord', year: '2019'),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    CarItem(carName: 'Nissan Altima', year: '2021'),
                    SizedBox(height: 30.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+Add more vehicles',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Color(ConstColors.mainColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
