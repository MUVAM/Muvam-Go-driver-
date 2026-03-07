import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/ride_item.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/weekly_earnings_chart.dart';

class OverviewTab extends StatelessWidget {
  final EarningsProvider earningsProvider;
  final int selectedPeriodIndex;

  const OverviewTab({
    super.key,
    required this.earningsProvider,
    required this.selectedPeriodIndex,
  });

  String _getChartTitle() {
    switch (selectedPeriodIndex) {
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
    switch (selectedPeriodIndex) {
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

  @override
  Widget build(BuildContext context) {
    final overview = earningsProvider.weeklyOverview;
    final recentRides = earningsProvider.recentRides;
    final totalEarnings = overview?.totalEarnings ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.kWhiteColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.all(18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuvamTexts.bodyLarge16(
                context,
                text: _getChartTitle(),
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
              SizedBox(height: 20.h),
              WeeklyEarningsChart(overview: overview),
              SizedBox(height: 20.h),
              Center(
                child: Column(
                  children: [
                    MuvamTexts.titleMedium18(
                      context,
                      text: earningsProvider.formatPrice(totalEarnings),
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlackColor,
                    ),
                    SizedBox(height: 4.h),
                    MuvamTexts.bodyMedium14(
                      context,
                      text: _getTotalLabel(),
                      isTextWidget: true,
                      fontWeight: FontWeight.w400,
                      color: AppColors.kBlackColor,
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
              color: AppColors.kWhiteColor,
              borderRadius: BorderRadius.circular(15.r),
            ),
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuvamTexts.bodyLarge16(
                  context,
                  text: 'Recent rides',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 15.h),
                ...recentRides.rides.take(3).map((ride) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: RideItem(
                      location: ride.destinationAddress,
                      time: earningsProvider.formatDateTime(ride.createdAt),
                      amount: earningsProvider.formatPrice(ride.amount),
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
}
