import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class InAppNotificationService {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  static void showMessageNotification({
    required BuildContext context,
    required String senderName,
    required String message,
    required int rideId,
    String? senderImage,
    VoidCallback? onTap,
  }) {
    AppLogger.log('InAppNotificationService: showMessageNotification called');
    AppLogger.log('   Sender: $senderName');
    AppLogger.log('   Message: "$message"');
    AppLogger.log('   Ride ID: $rideId');

    if (_isShowing) {
      AppLogger.log('InAppNotificationService: Already showing, hiding first');
      hide();
    }

    _isShowing = true;
    AppLogger.log('InAppNotificationService: Starting notification display');

    final overlay = context.findRenderObject() as RenderObject?;
    AppLogger.log(
      'InAppNotificationService: Overlay context found: ${overlay != null}',
    );

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 10.w,
        right: 10.w,
        child: Material(
          color: Colors.transparent,
          child: _MessageNotificationCard(
            senderName: senderName,
            message: message,
            senderImage: senderImage,
            onTap: () {
              AppLogger.log('InAppNotificationService: Notification tapped');
              hide();
              onTap?.call();
            },
            onDismiss: hide,
          ),
        ),
      ),
    );

    final overlayManager = Overlay.of(context);
    overlayManager.insert(_currentOverlay!);
    AppLogger.log('InAppNotificationService: Overlay inserted');

    Future.delayed(Duration(seconds: 5), () {
      if (_isShowing) {
        AppLogger.log(
          'InAppNotificationService: Auto-dismissing after 5 seconds',
        );
        hide();
      }
    });
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _isShowing = false;
  }
}

class _MessageNotificationCard extends StatefulWidget {
  final String senderName;
  final String message;
  final String? senderImage;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _MessageNotificationCard({
    required this.senderName,
    required this.message,
    required this.onTap,
    required this.onDismiss,
    this.senderImage,
  });

  @override
  State<_MessageNotificationCard> createState() =>
      _MessageNotificationCardState();
}

class _MessageNotificationCardState extends State<_MessageNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < -500) {
              _handleDismiss();
            }
          },
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                  backgroundImage:
                      widget.senderImage != null &&
                          widget.senderImage!.isNotEmpty
                      ? NetworkImage(widget.senderImage!)
                      : null,
                  child:
                      widget.senderImage == null || widget.senderImage!.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Color(0xFF2196F3),
                          size: 24.sp,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.senderName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chat_bubble,
                            size: 14.sp,
                            color: Color(0xFF2196F3),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _handleDismiss,
                  child: Icon(
                    Icons.close,
                    size: 20.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
