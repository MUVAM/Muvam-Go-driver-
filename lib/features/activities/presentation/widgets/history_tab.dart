import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/history_item.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_cancelled_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_completed_screen.dart';
import 'package:provider/provider.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return Center(child: CircularProgressIndicator.adaptive());
        }

        if (provider.errorMessage != null && !provider.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  provider.errorMessage ?? 'Failed to load rides',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => provider.fetchRides(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final historyRides = provider.historyRides;

        if (historyRides.isEmpty) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                SvgPicture.asset(
                  ConstImages.clockCircleIcon,
                  width: 120.w,
                  height: 120.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Nothing here for now. Ready to take \nyour fast ride',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (provider.isRefreshing) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: historyRides.length,
          itemBuilder: (context, index) {
            final ride = historyRides[index];
            final dateTime = DateTime.parse(
              ride.scheduledAt ?? ride.createdAt,
            ).toLocal();

            final timeFormat = DateFormat('h:mma');
            final formattedTime = timeFormat.format(dateTime).toLowerCase();

            final dateFormat = DateFormat('MMM d, yyyy');
            final formattedDate = dateFormat.format(dateTime);

            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: HistoryItem(
                time: formattedTime,
                date: formattedDate,
                destination: ride.destAddress,
                isCompleted: ride.isCompleted,
                price: ride.isCompleted
                    ? provider.formatPrice(ride.price)
                    : null,
                onTap: () {
                  if (ride.isCompleted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryCompletedScreen(rideId: ride.id),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryCancelledScreen(rideId: ride.id),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
