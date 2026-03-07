import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/features/analytics/data/models/overview_response_model.dart';

class WeeklyEarningsChart extends StatelessWidget {
  final WeeklyOverviewData? overview;

  const WeeklyEarningsChart({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    if (overview == null || overview!.dailyBreakdown.isEmpty) {
      return Container(
        width: double.infinity,
        height: 70.h,
        child: Center(
          child: MuvamTexts.bodyMedium14(
            context,
            text: 'No data available',
            isTextWidget: true,
            color: AppColors.kGreyColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 140.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 ||
                      value.toInt() >= overview!.dailyBreakdown.length) {
                    return const SizedBox.shrink();
                  }
                  final day = overview!.dailyBreakdown[value.toInt()];
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MuvamTexts.bodySmall12(
                          context,
                          text: day.dayLabel,
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlackColor,
                        ),
                        SizedBox(height: 2.h),
                        MuvamTexts.bodySmall12(
                          // changed from headlineSmall24
                          context,
                          text: _formatAmount(day.amount),
                          isTextWidget: true,
                          fontWeight: FontWeight.w400,
                          color: AppColors.kBlackColor.withOpacity(0.87),
                        ),
                      ],
                    ),
                  );
                },
                reservedSize: 56.h,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _createBarGroups(),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (overview == null || overview!.dailyBreakdown.isEmpty) return 100;

    final maxAmount = overview!.dailyBreakdown
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    return maxAmount > 0 ? maxAmount * 1.2 : 100;
  }

  List<BarChartGroupData> _createBarGroups() {
    return overview!.dailyBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: day.amount > 0 ? day.amount : 0.5,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A9D7A), Color(0xFF1F5D42)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 28.w,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(6.r),
              bottom: Radius.circular(2.r),
            ),
          ),
        ],
      );
    }).toList();
  }

  String _formatAmount(double amount) {
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
