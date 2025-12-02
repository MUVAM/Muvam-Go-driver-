import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/ratings/presentation/widgets/rating_item.dart';

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

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
            Image.asset(ConstImages.avatar, width: 80.w, height: 80.h),
            SizedBox(height: 20.h),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 5.w : 0),
                  child: Icon(
                    Icons.star,
                    size: 24.sp,
                    color: index < 4 ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
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
                    RatingItem(
                      name: 'Sarah Johnson',
                      rating: 5,
                      time: '2 hours ago',
                      comment:
                          'Great driver! Very professional and the car was clean. Highly recommend.',
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    RatingItem(
                      name: 'Mike Chen',
                      rating: 4,
                      time: '1 day ago',
                      comment:
                          'Good service, arrived on time. The ride was smooth and comfortable.',
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    RatingItem(
                      name: 'Emma Wilson',
                      rating: 5,
                      time: '3 days ago',
                      comment:
                          'Excellent experience! The driver was friendly and knew the best routes.',
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    RatingItem(
                      name: 'David Brown',
                      rating: 4,
                      time: '1 week ago',
                      comment:
                          'Very reliable service. The car was in good condition and the driver was polite.',
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
