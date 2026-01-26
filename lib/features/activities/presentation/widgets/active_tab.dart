import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/trip_card.dart';
import 'package:muvam_rider/features/trips/presentation/screen/active_trip_screen.dart';
import 'package:provider/provider.dart';

class ActiveTab extends StatelessWidget {
  const ActiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(ConstColors.mainColor),
            ),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load rides',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
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

        final activeRides = provider.activeRides;

        if (activeRides.isEmpty) {
          return Center(
            child: Column(
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
                  'Just chilling for now. Book a ride \nwhen you’re ready',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: activeRides.map((ride) {
            // Parse the datetime string
            final dateTime = DateTime.parse(
              ride.scheduledAt ?? ride.createdAt,
            ).toLocal();

            // Format time: 8:30pm
            final timeFormat = DateFormat('h:mma');
            final formattedTime = timeFormat.format(dateTime).toLowerCase();

            // Format date: Jan 26, 2026
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
                    builder: (context) => ActiveTripScreen(rideId: ride.id),
                  ),
                ),
                isActive: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
