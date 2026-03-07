import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/currency_formatter.dart';

class RideSheetContent {
  static Widget buildActiveRideContent({
    required BuildContext context,
    required Map<String, dynamic> ride,
    required Map<String, dynamic> passenger,
    required int tip,
    required int waitFee,
    required String passengerID,
    required String passengerName,
    required String passengerPhone,
    required String rideStatus,
    required Function formatPaymentMethod,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: MuvamTexts.headlineMedium28(
            context,
            text:
                '₦${CurrencyFormatter.format(ride['Price'].toStringAsFixed(1))}',
            isTextWidget: true,
            fontWeight: FontWeight.w700,
            color: AppColors.kBlackColor,
          ),
        ),
        SizedBox(height: 15.h),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MuvamTexts.bodyLarge16(
                context,
                text: 'Extra(tip): ₦$tip',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
                color: AppColors.kGreyColor,
              ),
              SizedBox(width: 8.w),
              Container(width: 1.w, height: 20.h, color: Colors.grey.shade300),
              SizedBox(width: 8.w),
              MuvamTexts.bodyLarge16(
                context,
                text: 'Wait: ₦$waitFee',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
                color: AppColors.kGreyColor,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        if (rideStatus != 'started') ...[
          MuvamTexts.headlineSmall24(
            context,
            text: passengerName,
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
          SizedBox(height: 15.h),
          MuvamTexts.headlineSmall24(
            context,
            text: 'Pick up: ${ride['PickupAddress'] ?? 'Unknown location'}',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
          if (ride['StopAddress'].trim().isNotEmpty) SizedBox(height: 15.h),
        ],
        if (ride['StopAddress'].trim().isNotEmpty)
          MuvamTexts.headlineSmall24(
            context,
            text: 'Stop: ${ride['StopAddress'] ?? ride['stopAddress'] ?? ''}',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
        SizedBox(height: 15.h),
        MuvamTexts.headlineSmall24(
          context,
          text: 'Destination: ${ride['DestAddress'] ?? 'Unknown destination'}',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 15.h),
        Divider(color: AppColors.kGreyColor),
        SizedBox(height: 15.h),
        if (ride['Note'].trim().isNotEmpty)
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: MuvamTexts.headlineSmall24(
                  context,
                  text: 'Note:',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 331.w,
                  child: MuvamTexts.bodyLarge16(
                    context,
                    text:
                        '${ride['note'] ?? ride['Note'] ?? 'No note provided'}',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: 15.h),
        Container(
          width: 353.w,
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(width: 0.6, color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/payincar1.png',
                width: 55.w,
                height: 30.h,
              ),
              SizedBox(width: 8.w),
              MuvamTexts.bodyMedium14(
                context,
                text: formatPaymentMethod(ride['PaymentMethod']),
                isTextWidget: true,
                color: AppColors.kBlackColor,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        if (rideStatus != 'started') ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      AppRoutes.chat.name,
                      extra: {
                        'rideId': ride['ID'],
                        'driverName': passengerName,
                        'driverId': passengerID,
                        'driverImage': null,
                        'driverPhone': passengerPhone,
                      },
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat,
                        size: 16.sp,
                        color: AppColors.kBlackColor,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: MuvamTexts.titleMedium18(
                          context,
                          text:
                              'Chat ${passenger['first_name'] ?? 'Passenger'}',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlackColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1.w, height: 30.h, color: Colors.grey.shade300),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      AppRoutes.call.name,
                      extra: {
                        'driverName': passengerName,
                        'rideId': ride['ID'],
                      },
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call,
                        size: 16.sp,
                        color: AppColors.kBlackColor,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: MuvamTexts.titleMedium18(
                          context,
                          text:
                              'Call ${passenger['first_name'] ?? 'Passenger'}',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlackColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 45.h),
        ],
      ],
    );
  }

  static Widget buildCompletedContent({
    required BuildContext context,
    required Map<String, dynamic> ride,
    required String passengerName,
    required Function formatPaymentMethod,
  }) {
    final note = ride['Note'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: MuvamTexts.headlineSmall24(
            context,
            text: 'Amount',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: MuvamTexts.headlineMedium28(
            context,
            text: '₦${ride['Price'].toStringAsFixed(1)}',
            isTextWidget: true,
            fontWeight: FontWeight.w700,
            color: AppColors.kBlackColor,
          ),
        ),
        SizedBox(height: 20.h),
        MuvamTexts.headlineSmall24(
          context,
          text: 'Passenger name',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 10.h),
        MuvamTexts.bodyLarge16(
          context,
          text: passengerName,
          isTextWidget: true,
          fontWeight: FontWeight.w400,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 20.h),
        MuvamTexts.headlineSmall24(
          context,
          text: 'Destination',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 10.h),
        MuvamTexts.bodyLarge16(
          context,
          text: ride['DestAddress'] ?? 'Unknown destination',
          isTextWidget: true,
          fontWeight: FontWeight.w400,
          color: AppColors.kBlackColor,
        ),
        if (ride['StopAddress'] != null &&
            ride['StopAddress'].toString().isNotEmpty) ...[
          SizedBox(height: 20.h),
          MuvamTexts.headlineSmall24(
            context,
            text: 'Stop',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
          SizedBox(height: 10.h),
          MuvamTexts.bodyLarge16(
            context,
            text: ride['StopAddress'],
            isTextWidget: true,
            fontWeight: FontWeight.w400,
            color: AppColors.kBlackColor,
          ),
        ],
        if (note.isNotEmpty) ...[
          SizedBox(height: 20.h),
          MuvamTexts.headlineSmall24(
            context,
            text: 'Note',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlackColor,
          ),
          SizedBox(height: 10.h),
          MuvamTexts.bodyLarge16(
            context,
            text: note,
            isTextWidget: true,
            fontWeight: FontWeight.w400,
            color: AppColors.kBlackColor,
          ),
        ],
        SizedBox(height: 20.h),
        MuvamTexts.headlineSmall24(
          context,
          text: 'Payment Method',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 10.h),
        MuvamTexts.bodyLarge16(
          context,
          text: formatPaymentMethod(ride['PaymentMethod']),
          isTextWidget: true,
          fontWeight: FontWeight.w400,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 30.h),
        Container(
          width: 353.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: AppColors.kMainColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: GestureDetector(
            onTap: () {
              context.pushNamed(
                AppRoutes.historyCompleted.name,
                extra: {'rideId': ride['ride_id']},
              );
            },
            child: Center(
              child: MuvamTexts.button16(
                context,
                text: 'History',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kWhiteColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
