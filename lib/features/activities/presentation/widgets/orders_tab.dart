import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/trip_card.dart';
import 'package:muvam_rider/features/trips/presentation/screen/trip_details_screen.dart';
import 'package:provider/provider.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(ConstColors.mainColor),
            ),
          );
        }

        if (provider.errorMessage != null && !provider.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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

        final prebookedRides = provider.prebookedRides;

        if (prebookedRides.isEmpty) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                SvgPicture.asset(
                  ConstImages.carIcon,
                  width: 120.w,
                  height: 120.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  "Just relaxing for now. Go ahead and order \na ride whenever you're ready",
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
          itemCount: prebookedRides.length,
          itemBuilder: (context, index) {
            final ride = prebookedRides[index];
            final dateTime = DateTime.parse(
              ride.scheduledAt ?? ride.createdAt,
            ).toLocal();

            final timeFormat = DateFormat('h:mma');
            final formattedTime = timeFormat.format(dateTime).toLowerCase();

            final dateFormat = DateFormat('MMM d, yyyy');
            final formattedDate = dateFormat.format(dateTime);

            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: TripCard(
                time: formattedTime,
                date: formattedDate,
                destination: ride.destAddress,
                tripId: '#${ride.id}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDetailsScreen(rideId: ride.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
