import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/analytics/data/models/earning_over_view_model.dart';

class WeeklyEarningsChart extends StatelessWidget {
  final WeeklyOverviewData? overview;
  final String Function(double) formatPrice;

  const WeeklyEarningsChart({
    Key? key,
    required this.overview,
    required this.formatPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (overview == null || overview!.dailyBreakdown.isEmpty) {
      return Container(
        width: 318.w,
        height: 109.h,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(children: [_buildBarChart(overview!.dailyBreakdown)]);
  }

  Widget _buildBarChart(List<DailyEarning> dailyData) {
    // Find the maximum amount for scaling
    double maxAmount = dailyData.isEmpty
        ? 1
        : dailyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    // Ensure we have a reasonable max for scaling
    if (maxAmount <= 0) maxAmount = 1;

    return Container(
      width: 318.w,
      height: 109.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dailyData.map((day) {
          return _buildBarItem(
            label: day.dayLabel,
            amount: day.amount,
            maxAmount: maxAmount,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarItem({
    required String label,
    required double amount,
    required double maxAmount,
  }) {
    // Calculate bar height as percentage of max height (80% of container)
    final maxBarHeight = 70.h;
    final barHeight = (amount / maxAmount) * maxBarHeight;
    final minHeight = 20.h; // Minimum visible height
    final finalHeight = barHeight < minHeight ? minHeight : barHeight;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Bar
            Container(
              height: finalHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A9D7A), Color(0xFF1F5D42)],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(6.r),
                  bottom: Radius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Day label
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 1.h),
            // Amount
            Text(
              _formatAmount(amount),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    // Convert to thousands format with # symbol
    if (amount >= 1000) {
      final thousands = (amount / 1000).toStringAsFixed(0);
      final remainder = (amount % 1000).toInt();
      if (remainder == 0) {
        return '#$thousands,000';
      } else {
        return '#$thousands,${remainder.toString().padLeft(3, '0')}';
      }
    }
    return '#${amount.toStringAsFixed(0)}';
  }
}
