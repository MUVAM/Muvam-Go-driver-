import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/trip_card.dart';
import 'package:provider/provider.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    String formatTime(String dateTimeStr) {
      try {
        final dateTime = DateTime.parse(dateTimeStr).toLocal();
        return DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        return '';
      }
    }

    String formatDate(String dateTimeStr) {
      try {
        final dateTime = DateTime.parse(dateTimeStr).toLocal();
        return DateFormat('MMMM d, yyyy').format(dateTime);
      } catch (e) {
        return '';
      }
    }

    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.kMainColor),
          );
        }

        if (provider.errorMessage != null && !provider.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48.sp,
                  color: AppColors.kFailureColor,
                ),
                SizedBox(height: 16.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: provider.errorMessage ?? 'Failed to load rides',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kBlackColor,
                  center: true,
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => provider.fetchRides(),
                  child: MuvamTexts.button16(
                    context,
                    text: 'Retry',
                    isTextWidget: true,
                    color: AppColors.kMainColor,
                  ),
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
                MuvamTexts.bodyMedium14(
                  context,
                  text:
                      "Just relaxing for now. Go ahead and order \na ride whenever you're ready",
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: AppColors.kGreyColor,
                  center: true,
                ),
                if (provider.isRefreshing) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.kMainColor,
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

            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: TripCard(
                time: formatTime(ride.createdAt),
                date: formatDate(ride.createdAt),
                destination: ride.destAddress,
                tripId: '#${ride.id}',
                onTap: () {
                  context.pushNamed('tripDetails', extra: {'rideId': ride.id});
                },
              ),
            );
          },
        );
      },
    );
  }
}
