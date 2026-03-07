import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class RideInfoWidget extends StatefulWidget {
  final String eta;
  final String location;
  final String rideStatus;

  const RideInfoWidget({
    super.key,
    required this.eta,
    required this.location,
    required this.rideStatus,
  });

  @override
  State<RideInfoWidget> createState() => _RideInfoWidgetState();
}

class _RideInfoWidgetState extends State<RideInfoWidget> {
  double _topPosition = 140.0;
  double _leftPosition = 20.0;

  @override
  Widget build(BuildContext context) {
    String title = _getTitle();
    String subtitle = _getSubtitle();

    return Positioned(
      top: _topPosition,
      left: _leftPosition,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: _buildWidgetContent(title, subtitle, isDragging: true),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            _topPosition = details.offset.dy;
            _leftPosition = details.offset.dx;

            if (_topPosition < 60) _topPosition = 60;
            if (_leftPosition < 0) _leftPosition = 0;
            if (_leftPosition > MediaQuery.of(context).size.width - 353.w) {
              _leftPosition = MediaQuery.of(context).size.width - 353.w;
            }
          });
        },
        child: _buildWidgetContent(title, subtitle),
      ),
    );
  }

  Widget _buildWidgetContent(
    String title,
    String subtitle, {
    bool isDragging = false,
  }) {
    return Container(
      width: 353.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.kBlackColor.withOpacity(isDragging ? 0.3 : 0.1),
            blurRadius: isDragging ? 20 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.kMainColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: widget.eta
                        .replaceAll(' min', '')
                        .replaceAll('< ', '')
                        .replaceAll('s', 'm'),
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kWhiteColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuvamTexts.bodyLarge16(
                      context,
                      text: title,
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlackColor,
                    ),
                    SizedBox(height: 2.h),
                    MuvamTexts.bodySmall12(
                      context,
                      text: subtitle,
                      isTextWidget: true,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
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
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: widget.location,
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kBlackColor.withOpacity(0.87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.rideStatus) {
      case 'accepted':
        return '${widget.eta} to pickup';
      case 'arrived':
        return 'Arrived at pickup';
      case 'started':
        return '${widget.eta} to destination';
      default:
        return '${widget.eta} away';
    }
  }

  String _getSubtitle() {
    switch (widget.rideStatus) {
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
    switch (widget.rideStatus) {
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
    switch (widget.rideStatus) {
      case 'accepted':
      case 'arrived':
        return AppColors.kSuccessColor;
      case 'started':
        return AppColors.kFailureColor;
      default:
        return AppColors.kMainColor;
    }
  }
}
