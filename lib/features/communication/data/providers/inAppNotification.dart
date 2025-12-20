import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class InAppNotificationService {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// Show an in-app notification for incoming messages
  static void showMessageNotification({
    required BuildContext context,
    required String senderName,
    required String message,
    required int rideId,
    String? senderImage,
    VoidCallback? onTap,
  }) {
    print('🔔 InAppNotificationService: showMessageNotification called');
    print('   Sender: $senderName');
    print('   Message: "$message"');
    print('   Ride ID: $rideId');
    
    // Don't show if already showing a notification
    if (_isShowing) {
      print('⚠️ InAppNotificationService: Already showing, hiding first');
      hide();
    }

    _isShowing = true;
    print('✅ InAppNotificationService: Starting notification display');

    final overlay = context.findRenderObject() as RenderObject?;
    print('🎨 InAppNotificationService: Overlay context found: ${overlay != null}');

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
              print('🖱️ InAppNotificationService: Notification tapped');
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
    print('✅ InAppNotificationService: Overlay inserted');

    // Auto-dismiss after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (_isShowing) {
        print('⏰ InAppNotificationService: Auto-dismissing after 5 seconds');
        hide();
      }
    });
  }

  /// Hide the current notification
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
                // Sender avatar
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
                // Message content
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
                // Dismiss button
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
