import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import 'edit_full_name_screen.dart';
import 'delete_account_screen.dart';
import 'my_cars_screen.dart';
import 'ratings_screen.dart';

class ProfileScreen extends StatelessWidget {
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
                        'My Account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w), // Balance the back button
                ],
              ),
            ),
            SizedBox(height: 40.h),
            Stack(
              children: [
                Image.asset(
                  ConstImages.avatar,
                  width: 80.w,
                  height: 80.h,
                ),
                Positioned(
                  top: 6.h,
                  left: 51.w,
                  child: Container(
                    width: 18.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Star rating
            Container(
              width: 120.w,
              height: 20.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 5.w : 0),
                  child: Icon(
                    Icons.star,
                    size: 20.sp,
                    color: index < 4 ? Colors.amber : Colors.grey.shade300,
                  ),
                )),
              ),
            ),
            SizedBox(height: 10.h),
            // View ratings
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RatingsScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View ratings',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.black),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileField('Full name', 'John Doe', hasEdit: true, onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditFullNameScreen()),
                      );
                    }),
                    SizedBox(height: 15.h),
                    _buildProfileField('Phone number', '+234 123 456 7890'),
                    SizedBox(height: 15.h),
                    _buildProfileField('Date of birth', 'January 1, 1990'),
                    SizedBox(height: 15.h),
                    _buildProfileField('Email address', 'john.doe@email.com'),
                    SizedBox(height: 15.h),
                    _buildProfileField('State', 'Lagos'),
                    SizedBox(height: 30.h),
                    // My Car section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Car',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            '+ Add another vehicle',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.32,
                              color: Color(ConstColors.mainColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    GestureDetector(
                      onTap: () => _navigateToMyCarsScreen(context),
                      child: Container(
                        width: 353.w,
                        height: 47.h,
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F9F8),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  ConstImages.car,
                                  width: 20.w,
                                  height: 20.h,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'Active car',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Container(
                      width: 353.w,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: () => _showLogoutSheet(context),
                        child: Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeleteAccountScreen()),
                          );
                        },
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool hasEdit = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB1B1B1),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: Color(0xFFF7F9F8),
            borderRadius: BorderRadius.circular(3.r),
          ),
          padding: EdgeInsets.only(
            top: 15.h,
            right: 14.w,
            bottom: 15.h,
            left: 14.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              if (hasEdit)
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToMyCarsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyCarsScreen()),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Are you sure you want to log out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Container(
                  width: 170.w,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: Color(0xFFB1B1B1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Center(
                    child: Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  width: 170.w,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}