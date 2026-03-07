import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/earnings_tab.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/main_tab.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/overview_tab.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/period_tab.dart';
import 'package:muvam_rider/features/analytics/presentation/widgets/stat_card.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  AnalyticsScreenState createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriodIndex = 0;
  int _selectedTabIndex = 0;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() async {
    final earningsProvider = Provider.of<EarningsProvider>(
      context,
      listen: false,
    );

    final hasData =
        earningsProvider.earningsSummary != null ||
        earningsProvider.weeklyOverview != null ||
        earningsProvider.earningsBreakdown != null;

    if (hasData && !_hasLoadedOnce) {
      setState(() {
        _hasLoadedOnce = true;
      });
      _refreshDataInBackground();
    } else if (!hasData) {
      final period = earningsProvider.getPeriodFromIndex(_selectedPeriodIndex);

      await Future.wait([
        earningsProvider.fetchEarningsSummary(period),
        earningsProvider.fetchEarningsOverview(period),
        earningsProvider.fetchEarningsBreakdown(_selectedPeriodIndex),
      ]);

      if (mounted) {
        setState(() {
          _hasLoadedOnce = true;
        });
      }
    } else {
      _refreshDataInBackground();
    }
  }

  void _refreshDataInBackground() {
    final earningsProvider = Provider.of<EarningsProvider>(
      context,
      listen: false,
    );
    final period = earningsProvider.getPeriodFromIndex(_selectedPeriodIndex);

    Future.wait([
      earningsProvider.fetchEarningsSummary(period),
      earningsProvider.fetchEarningsOverview(period),
      earningsProvider.fetchEarningsBreakdown(_selectedPeriodIndex),
    ]);
  }

  void _onPeriodTabSelected(int index) {
    setState(() => _selectedPeriodIndex = index);
    _fetchData();
  }

  void _onMainTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kFormFieldColor,
      body: Consumer<EarningsProvider>(
        builder: (context, earningsProvider, child) {
          final shouldShowLoader =
              !_hasLoadedOnce && earningsProvider.earningsSummary == null;

          return SafeArea(
            child: shouldShowLoader
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.kMainColor,
                    ),
                  )
                : Column(
                    children: [
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
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100.r),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: AppColors.kBlackColor,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                            MuvamTexts.headlineSmall24(
                              context,
                              text: 'Analytics',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kBlackColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Container(
                          width: double.infinity,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.all(2.w),
                          child: Row(
                            children: [
                              PeriodTab(
                                text: 'Today',
                                index: 0,
                                selectedIndex: _selectedPeriodIndex,
                                onTap: _onPeriodTabSelected,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 7.h),
                                width: 0.5.w,
                                height: 36.h,
                                color: Colors.grey.shade300,
                              ),
                              PeriodTab(
                                text: 'Weekly',
                                index: 1,
                                selectedIndex: _selectedPeriodIndex,
                                onTap: _onPeriodTabSelected,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 7.h),
                                width: 0.5.w,
                                height: 36.h,
                                color: Colors.grey.shade300,
                              ),
                              PeriodTab(
                                text: 'Monthly',
                                index: 2,
                                selectedIndex: _selectedPeriodIndex,
                                onTap: _onPeriodTabSelected,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 15.h,
                          crossAxisSpacing: 15.w,
                          childAspectRatio: 170.w / 95.h,
                          children: [
                            StatCard(
                              value:
                                  earningsProvider.earningsSummary?.totalRides
                                      .toString() ??
                                  '0',
                              label: _getPeriodLabel(),
                              bgColor: const Color(0xFFF0FDF4),
                              valueColor: AppColors.kMainColor,
                            ),
                            StatCard(
                              value: earningsProvider.formatPrice(
                                earningsProvider
                                        .earningsSummary
                                        ?.totalEarnings ??
                                    0,
                              ),
                              label: 'Earnings',
                              bgColor: const Color(0xFFE2EBFF),
                              valueColor: const Color(0xFF2664EB),
                            ),
                            StatCard(
                              value: Provider.of<ProfileProvider>(
                                context,
                              ).userRating.toStringAsFixed(1),
                              label: 'Ratings',
                              bgColor: const Color(0xFFFEFBE8),
                              valueColor: const Color(0xFFCA8A00),
                            ),
                            StatCard(
                              value: earningsProvider.formatHours(
                                earningsProvider.earningsSummary?.onlineHours ??
                                    0,
                                earningsProvider
                                        .earningsSummary
                                        ?.onlineMinutes ??
                                    0,
                              ),
                              label: 'Hours online',
                              bgColor: const Color(0xFFF1F0F2),
                              valueColor: const Color(0xFF9334EA),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Container(
                          width: double.infinity,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.all(2.w),
                          child: Row(
                            children: [
                              MainTab(
                                text: 'Overview',
                                index: 0,
                                selectedIndex: _selectedTabIndex,
                                onTap: _onMainTabSelected,
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 7.h),
                                width: 0.5.w,
                                height: 36.h,
                                color: Colors.grey.shade300,
                              ),
                              MainTab(
                                text: 'Earnings',
                                index: 1,
                                selectedIndex: _selectedTabIndex,
                                onTap: _onMainTabSelected,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: _selectedTabIndex == 0
                              ? OverviewTab(
                                  earningsProvider: earningsProvider,
                                  selectedPeriodIndex: _selectedPeriodIndex,
                                )
                              : EarningsTab(earningsProvider: earningsProvider),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
