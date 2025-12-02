import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';

class RatingsScreen extends StatelessWidget {
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
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Ratings',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            // User avatar
            Image.asset(
              ConstImages.avatar,
              width: 80.w,
              height: 80.h,
            ),
            SizedBox(height: 20.h),
            // User name
            Text(
              'John Doe',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15.h),
            // Total rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => Padding(
                padding: EdgeInsets.only(right: index < 4 ? 5.w : 0),
                child: Icon(
                  Icons.star,
                  size: 24.sp,
                  color: index < 4 ? Colors.amber : Colors.grey.shade300,
                ),
              )),
            ),
            SizedBox(height: 30.h),
            // What your passengers said
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What your passengers said',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.2,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildRatingItem('Sarah Johnson', 5, '2 hours ago', 'Great driver! Very professional and the car was clean. Highly recommend.'),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    _buildRatingItem('Mike Chen', 4, '1 day ago', 'Good service, arrived on time. The ride was smooth and comfortable.'),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    _buildRatingItem('Emma Wilson', 5, '3 days ago', 'Excellent experience! The driver was friendly and knew the best routes.'),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    _buildRatingItem('David Brown', 4, '1 week ago', 'Very reliable service. The car was in good condition and the driver was polite.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(String name, int rating, String time, String comment) {
    return Container(
      width: 343.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          Image.asset(
            ConstImages.avatar,
            width: 38.w,
            height: 38.h,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5.h),
                // Rating and time
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) => Padding(
                        padding: EdgeInsets.only(right: index < 4 ? 2.w : 0),
                        child: Icon(
                          Icons.star,
                          size: 14.sp,
                          color: index < rating ? Colors.amber : Colors.grey.shade300,
                        ),
                      )),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Comment
                Text(
                  comment,
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.48,
                    letterSpacing: -0.13,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}