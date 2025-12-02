import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriodIndex = 0;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 70.h,
            left: 20.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            child: Text(
              'Analytics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: 140.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildPeriodTab('Today', 0),
                  Container(width: 0.5.w, height: 36.h, color: Theme.of(context).dividerColor),
                  _buildPeriodTab('Weekly', 1),
                  Container(width: 0.5.w, height: 36.h, color: Theme.of(context).dividerColor),
                  _buildPeriodTab('Monthly', 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 195.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 200.h,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15.h,
                crossAxisSpacing: 15.w,
                childAspectRatio: 170.w / 95.h,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard('5', 'Today\'s ride', Color(0xFFF0FDF4), Color(0xFF2A8359)),
                  _buildStatCard('₦12,000', 'Earnings', Color(0xFFE2EBFF), Color(0xFF2664EB)),
                  _buildStatCard('4.8', 'Ratings', Color(0xFFFEFBE8), Color(0xFFCA8A00)),
                  _buildStatCard('8', 'Hours online', Color(0xFFF1F0F2), Color(0xFF9334EA)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 425.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildMainTab('Overview', 0),
                  Container(width: 0.5.w, height: 36.h, color: Theme.of(context).dividerColor),
                  _buildMainTab('Earnings', 1),
                ],
              ),
            ),
          ),
          Positioned(
            top: 485.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: SingleChildScrollView(
              child: _selectedTabIndex == 0 ? _buildOverviewTab() : _buildEarningsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String text, int index) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodIndex = index),
        child: Container(
          height: 38.h,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2A8359) : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Color(0xFFB1B1B1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTab(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          height: 38.h,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2A8359) : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Color(0xFFB1B1B1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor, Color valueColor) {
    return Container(
      width: 170.w,
      height: 95.h,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
              height: 1.0,
              letterSpacing: -0.41,
              color: valueColor,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              height: 1.0,
              letterSpacing: -0.41,
              color: Color(0xFF5B5B5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        Container(
          width: 353.w,
          height: 255.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This week',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  height: 20 / 16,
                  letterSpacing: -0.08,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 318.w,
                height: 109.h,
                child: Image.asset(
                  'assets/images/graph.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Column(
                  children: [
                    Text(
                      '₦128,000',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        height: 1.0,
                        letterSpacing: -0.08,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'total this week',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        height: 1.0,
                        letterSpacing: -0.08,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 25.h),
        Container(
          width: 353.w,
          height: 285.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent rides',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  height: 20 / 16,
                  letterSpacing: -0.08,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 15.h),
              _buildRideItem('Ikeja, Lagos', '2:30 PM', '4.5', '₦2,500'),
              SizedBox(height: 10.h),
              _buildRideItem('Victoria Island', '1:15 PM', '5.0', '₦3,200'),
              SizedBox(height: 10.h),
              _buildRideItem('Lekki Phase 1', '11:45 AM', '4.8', '₦1,800'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideItem(String location, String time, String rating, String amount) {
    return Container(
      width: 313.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                location,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  height: 20 / 16,
                  letterSpacing: -0.08,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      height: 20 / 14,
                      letterSpacing: -0.08,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.star, color: Colors.amber, size: 16.sp),
                  SizedBox(width: 2.w),
                  Text(
                    rating,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      height: 20 / 14,
                      letterSpacing: -0.08,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildEarningsTab() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 353.w,
              height: 147.h,
              decoration: BoxDecoration(
                color: Color(0xFF2A8359),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(15.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total earned',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₦245,000',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -54.h,
              left: -43.w,
              child: Container(
                width: 103.w,
                height: 103.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 99.h,
              left: 237.w,
              child: Container(
                width: 79.w,
                height: 79.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 89.h,
              left: 297.w,
              child: Container(
                width: 79.w,
                height: 79.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 25.h),
        Container(
          width: 353.w,
          height: 240.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings breakdown',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              _buildBreakdownItem('Gross earning', '₦280,000'),
              SizedBox(height: 15.h),
              _buildBreakdownItem('Tips received', '₦15,000'),
              SizedBox(height: 15.h),
              _buildBreakdownItem('Platform fee', '-₦50,000'),
              SizedBox(height: 15.h),
              Divider(color: Colors.grey.shade300),
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: Color(0xFF2A8359),
                    ),
                  ),
                  Text(
                    '₦245,000',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: Color(0xFF2A8359),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
            height: 20 / 14,
            letterSpacing: -0.08,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            height: 20 / 14,
            letterSpacing: -0.08,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}