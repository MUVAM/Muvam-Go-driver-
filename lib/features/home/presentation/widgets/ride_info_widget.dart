import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';

class RideInfoWidget extends StatelessWidget {
  final String eta;
  final String location;
  final String rideStatus;

  const RideInfoWidget({
    Key? key,
    required this.eta,
    required this.location,
    required this.rideStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = _getTitle();
    String subtitle = _getSubtitle();
    
    return Positioned(
      top: 140.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      eta.replaceAll(' min', '').replaceAll('< ', ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    _getLocationIcon(),
                    size: 16.sp,
                    color: _getLocationIconColor(),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (rideStatus) {
      case 'accepted':
        return '$eta to pickup';
      case 'arrived':
        return 'Arrived at pickup';
      case 'started':
        return '$eta to destination';
      default:
        return '$eta away';
    }
  }

  String _getSubtitle() {
    switch (rideStatus) {
      case 'accepted':
        return 'Driving to passenger location';
      case 'arrived':
        return 'Waiting for passenger';
      case 'started':
        return 'Trip in progress';
      default:
        return 'En route';
    }
  }

  IconData _getLocationIcon() {
    switch (rideStatus) {
      case 'accepted':
      case 'arrived':
        return Icons.person_pin_circle;
      case 'started':
        return Icons.location_on;
      default:
        return Icons.place;
    }
  }

  Color _getLocationIconColor() {
    switch (rideStatus) {
      case 'accepted':
      case 'arrived':
        return Colors.green;
      case 'started':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}