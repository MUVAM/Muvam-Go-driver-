import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/weekly_earnings_chart.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  AnalyticsScreenState createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriodIndex = 0;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final earningsProvider = Provider.of<EarningsProvider>(
      context,
      listen: false,
    );
    final period = earningsProvider.getPeriodFromIndex(_selectedPeriodIndex);
    earningsProvider.fetchEarningsSummary(period);
    if (_selectedTabIndex == 0) {
      earningsProvider.fetchWeeklyOverview('weekly');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<EarningsProvider>(
        builder: (context, earningsProvider, child) {
          return Stack(
            children: [
              Positioned(
                top: 40.h,
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
                      Container(
                        width: 0.5.w,
                        height: 36.h,
                        color: Theme.of(context).dividerColor,
                      ),
                      _buildPeriodTab('Weekly', 1),
                      Container(
                        width: 0.5.w,
                        height: 36.h,
                        color: Theme.of(context).dividerColor,
                      ),
                      _buildPeriodTab('Monthly', 2),
                    ],
                  ),
                ),
              ),
              if (earningsProvider.isLoading)
                Positioned(
                  top: 195.h,
                  left: 20.w,
                  child: Container(
                    width: 353.w,
                    height: 200.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2A8359),
                      ),
                    ),
                  ),
                )
              else
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
                        _buildStatCard(
                          earningsProvider.earningsSummary?.totalRides
                                  .toString() ??
                              '0',
                          'Today\'s ride',
                          Color(0xFFF0FDF4),
                          Color(0xFF2A8359),
                        ),
                        _buildStatCard(
                          earningsProvider.formatPrice(
                            earningsProvider.earningsSummary?.totalEarnings ??
                                0,
                          ),
                          'Earnings',
                          Color(0xFFE2EBFF),
                          Color(0xFF2664EB),
                        ),
                        _buildStatCard(
                          '4.8',
                          'Ratings',
                          Color(0xFFFEFBE8),
                          Color(0xFFCA8A00),
                        ),
                        _buildStatCard(
                          earningsProvider.formatHours(
                            earningsProvider.earningsSummary?.onlineHours ?? 0,
                            earningsProvider.earningsSummary?.onlineMinutes ??
                                0,
                          ),
                          'Hours online',
                          Color(0xFFF1F0F2),
                          Color(0xFF9334EA),
                        ),
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
                      Container(
                        width: 0.5.w,
                        height: 36.h,
                        color: Theme.of(context).dividerColor,
                      ),
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
                  child: _selectedTabIndex == 0
                      ? _buildOverviewTab(earningsProvider)
                      : _buildEarningsTab(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodTab(String text, int index) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriodIndex = index);
          _fetchData();
        },
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
        onTap: () {
          setState(() => _selectedTabIndex = index);
          if (index == 0) {
            final earningsProvider = Provider.of<EarningsProvider>(
              context,
              listen: false,
            );
            // CHANGED: fetchEarningsOverview to fetchWeeklyOverview
            earningsProvider.fetchWeeklyOverview('weekly');
          }
        },
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

  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color valueColor,
  ) {
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

  Widget _buildOverviewTab(EarningsProvider earningsProvider) {
    if (earningsProvider.isLoadingOverview) {
      return Container(
        height: 255.h,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2A8359)),
        ),
      );
    }

    // CHANGED: earningsOverview to weeklyOverview
    final overview = earningsProvider.weeklyOverview;
    final totalEarnings = overview?.totalEarnings ?? 0;

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
              WeeklyEarningsChart(
                overview: overview,
                formatPrice: earningsProvider.formatPrice,
              ),
              SizedBox(height: 20.h),
              Center(
                child: Column(
                  children: [
                    Text(
                      earningsProvider.formatPrice(totalEarnings),
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
        SizedBox(height: 15.h),
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

  Widget _buildRideItem(
    String location,
    String time,
    String rating,
    String amount,
  ) {
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
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A9D7A), Color(0xFF1F5D42)],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total earned',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '#58,589.00',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -30.h,
              left: -35.w,
              child: Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20.h,
              right: -10.w,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -15.h,
              right: 40.w,
              child: Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earning Breakdown',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 24.h),
              _buildBreakdownItem('Gross earning', '#45,099', false),
              SizedBox(height: 18.h),
              _buildBreakdownItem('Tips recieved', '#5,099', false),
              SizedBox(height: 18.h),
              _buildBreakdownItem('Platform fee', '#3,099', false),
              SizedBox(height: 18.h),
              Divider(color: Color(0xFFE5E5E5), thickness: 1),
              SizedBox(height: 18.h),
              _buildBreakdownItem('Platform fee', '#45,009', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, String amount, bool isTotal) {
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
