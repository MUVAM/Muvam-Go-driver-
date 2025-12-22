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
      earningsProvider.fetchEarningsOverview(period);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF9FAFC),
      body: Consumer<EarningsProvider>(
        builder: (context, earningsProvider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 35.w,
                            height: 35.h,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).disabledColor.withValues(alpha: 0.1),
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
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 24.sp,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Period Tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    width: double.infinity,
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

                SizedBox(height: 20.h),

                // Stats Grid
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: earningsProvider.isLoading
                      ? Container(
                          height: 200.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2A8359),
                            ),
                          ),
                        )
                      : GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 15.h,
                          crossAxisSpacing: 15.w,
                          childAspectRatio: 170.w / 95.h,
                          children: [
                            _buildStatCard(
                              earningsProvider.earningsSummary?.totalRides
                                      .toString() ??
                                  '0',
                              _getPeriodLabel(),
                              Color(0xFFF0FDF4),
                              Color(0xFF2A8359),
                            ),
                            _buildStatCard(
                              earningsProvider.formatPrice(
                                earningsProvider
                                        .earningsSummary
                                        ?.totalEarnings ??
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
                                earningsProvider.earningsSummary?.onlineHours ??
                                    0,
                                earningsProvider
                                        .earningsSummary
                                        ?.onlineMinutes ??
                                    0,
                              ),
                              'Hours online',
                              Color(0xFFF1F0F2),
                              Color(0xFF9334EA),
                            ),
                          ],
                        ),
                ),

                SizedBox(height: 20.h),

                // Main Tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    width: double.infinity,
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

                SizedBox(height: 20.h),

                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _selectedTabIndex == 0
                        ? _buildOverviewTab(earningsProvider)
                        : _buildEarningsTab(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriodIndex) {
      case 0:
        return 'Today\'s ride';
      case 1:
        return 'Weekly rides';
      case 2:
        return 'Monthly rides';
      default:
        return 'Today\'s ride';
    }
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
            final period = earningsProvider.getPeriodFromIndex(
              _selectedPeriodIndex,
            );
            earningsProvider.fetchEarningsOverview(period);
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
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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

    final overview = earningsProvider.weeklyOverview;
    final recentRides = earningsProvider.recentRides;
    final totalEarnings = overview?.totalEarnings ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getChartTitle(),
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
              WeeklyEarningsChart(overview: overview),
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
                      _getTotalLabel(),
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

        if (recentRides != null && recentRides.rides.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
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
                ...recentRides.rides.take(3).map((ride) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _buildRideItem(
                      ride.destinationAddress,
                      earningsProvider.formatDateTime(ride.createdAt),
                      earningsProvider.formatPrice(ride.amount),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        SizedBox(height: 20.h),
      ],
    );
  }

  String _getChartTitle() {
    switch (_selectedPeriodIndex) {
      case 0:
        return 'Today';
      case 1:
        return 'This week';
      case 2:
        return 'This month';
      default:
        return 'This week';
    }
  }

  String _getTotalLabel() {
    switch (_selectedPeriodIndex) {
      case 0:
        return 'total today';
      case 1:
        return 'total this week';
      case 2:
        return 'total this month';
      default:
        return 'total this week';
    }
  }

  Widget _buildRideItem(String location, String time, String amount) {
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
          padding: EdgeInsets.all(16.w),
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
              _buildBreakdownItem('Net earning', '#45,009', true),
            ],
          ),
        ),
        SizedBox(height: 20.h),
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
