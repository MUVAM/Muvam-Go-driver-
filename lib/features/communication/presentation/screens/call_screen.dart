import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import '../widgets/call_button.dart';

class CallScreen extends StatefulWidget {
  final String driverName;
  final int rideId;
  final int? sessionId;
  final bool isIncomingCall;

  const CallScreen({
    super.key, 
    required this.driverName, 
    required this.rideId,
    this.sessionId,
    this.isIncomingCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  String _callStatus = 'Calling...';
  int? _sessionId;
  int _callStartTime = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    await _callService.initialize();
    _callService.onCallStateChanged = (status) {
      if (mounted) {
        setState(() {
          _callStatus = status;
          if (status == 'Connected') {
            _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }
        });
      }
    };
    
    if (widget.isIncomingCall && widget.sessionId != null) {
      // For incoming calls, use the existing session ID
      _sessionId = widget.sessionId;
      setState(() {
        _callStatus = 'Connected';
        _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    } else {
      // For outgoing calls, initiate a new call
      try {
        final result = await _callService.initiateCall(widget.rideId);
        _sessionId = result['session_id'];
      } catch (e) {
        if (mounted) {
          setState(() {
            _callStatus = 'Call failed';
          });
        }
      }
    }
  }

  void _endCall() async {
    final duration = _callStartTime > 0 
        ? (DateTime.now().millisecondsSinceEpoch ~/ 1000) - _callStartTime 
        : 0;
    await _callService.endCall(_sessionId, duration);
    Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _callService.toggleSpeaker(_isSpeakerOn);
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 50.h),
            Stack(
              children: [
                Positioned(
                  left: 20.w,
                  child: Container(
                    width: 45.w,
                    height: 45.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.driverName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          height: 21 / 18,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        _callStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          height: 21 / 14,
                          letterSpacing: -0.32,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 50.h),
            Center(
              child: Container(
                width: 200.w,
                height: 200.h,
                child: CircleAvatar(
                  radius: 100.r,
                  backgroundImage: AssetImage(ConstImages.avatar),
                ),
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 72.h,
              margin: EdgeInsets.only(bottom: 49.h, left: 20.w, right: 20.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CallButton(
                    icon: Icons.chat,
                    iconColor: Colors.black,
                    onTap: () => Navigator.pop(context),
                  ),
                  CallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    iconColor: Colors.black,
                    onTap: _toggleSpeaker,
                  ),
                  CallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    iconColor: Colors.black,
                    onTap: _toggleMute,
                  ),
                  CallButton(
                    icon: Icons.call_end,
                    iconColor: Colors.white,
                    onTap: _endCall,
                    isEndCall: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}