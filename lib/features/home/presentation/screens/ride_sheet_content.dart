import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/utils/currency_formatter.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/communication/presentation/screens/chat_screen.dart';

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
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align everything to the left
      children: [
        // Price centered
        Center(
          child: Text(
            '₦${CurrencyFormatter.format(ride['Price'].toString())}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 36.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
        ),
        SizedBox(height: 15.h),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Extra(tip): ₦$tip',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 8.w), // Add spacing before divider
              Container(width: 1.w, height: 20.h, color: Colors.grey.shade300),
              SizedBox(width: 8.w),
              Text(
                'Wait: ₦$waitFee',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        if (rideStatus != 'started') ...[
          // Passenger name aligned to the left
          Text(
            passengerName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 15.h),
          // Pickup address aligned to the left
          Text(
            'Pick up: ${ride['PickupAddress'] ?? 'Unknown location'}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          if (ride['StopAddress'].trim().isNotEmpty) SizedBox(height: 15.h),
        ],
        // Destination aligned to the left
        if (ride['StopAddress'].trim().isNotEmpty)
          Text(
            'Stop: ${ride['StopAddress'] ?? ride['stopAddress']}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
        SizedBox(height: 15.h),
        Text(
          'Destination: ${ride['DestAddress'] ?? 'Unknown destination'}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 15.h),
        Divider(color: Color(0xffB1B1B1)),
        SizedBox(height: 15.h),
        if (ride['Note'].trim().isNotEmpty)
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 24.sp,
                    height: 1.0,
                    letterSpacing: -0.32,
                  ),
                ),
              ),
              Align(alignment:Alignment.centerLeft,
                child: Container(
                  width: 331.w,
                  child: Text(
                    maxLines: 2,
                    '${ride['note'] ?? ride['Note'] ?? 'No note provided'}',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 18.sp,
                      height: 1.0,
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height:15.h),
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
              // Icon(Ico, size: 20.sp),
              Image.asset(
                'assets/images/payincar1.png',
                width: 55.w,
                height: 30.h,
                // fit: BoxFit.contain,
              ),
              SizedBox(width: 8.w),
              Text(
                formatPaymentMethod(ride['PaymentMethod']),
                style: TextStyle(fontFamily: 'Inter', fontSize: 14.sp),
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
                    // Navigate to ChatScreen
                    // You'll need to import and use your ChatScreen here
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          driverName: passengerName,
                          driverId: passengerID,
                          rideId: ride['ID'],
                          driverPhone: passengerPhone,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 16.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Chat ${passenger['first_name'] ?? 'Passenger'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.41,
                          ),
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
                    // Navigate to CallScreen
                    // You'll need to import and use your CallScreen here
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          driverName: passengerName,
                          rideId: ride['ID'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call, size: 16.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Call ${passenger['first_name'] ?? 'Passenger'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            letterSpacing: -0.41,
                          ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align everything to the left
      children: [
        // Amount label centered
        Center(
          child: Text(
            'Amount',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // Price centered
        Center(
          child: Text(
            '₦${ride['Price'].toString()}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 36.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // Passenger name section - aligned to the left
        Text(
          'Passenger name',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          passengerName,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 20.h),
        // Destination section - aligned to the left
        Text(
          'Destination',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          ride['DestAddress'] ?? 'Unknown destination',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
        // Stop section - aligned to the left
        if (ride['StopAddress'] != null &&
            ride['StopAddress'].toString().isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'Stop',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            ride['StopAddress'],
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16.sp,
            ),
          ),
        ],
        if (note.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'Note',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              height: 1.0,
              letterSpacing: -0.32,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            note,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16.sp,
            ),
          ),
        ],
        SizedBox(height: 20.h),
        Text(
          'Payment Method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          formatPaymentMethod(ride['PaymentMethod']),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 30.h),
        Container(
          width: 353.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: Color(0xFF000000), // Replace with your ConstColors.mainColor
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: GestureDetector(
            onTap: () {
              // Navigate to HistoryCompletedScreen
              // You'll need to import and use your HistoryCompletedScreen here
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) =>
              //         HistoryCompletedScreen(rideId: ride['ride_id']),
              //   ),
              // );
            },
            child: Center(
              child: Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
