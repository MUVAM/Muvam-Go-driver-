import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/services/global_call_service.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/call_button.dart';

class CallScreen extends StatefulWidget {
  final String driverName;
  final int rideId;
  final int? sessionId;

  const CallScreen({
    super.key,
    required this.driverName,
    required this.rideId,
    this.sessionId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  CallService? _callService;
  String _callStatus = 'Connecting...';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Timer? _callTimer;
  int _callDuration = 0;
  int? _sessionId;
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    GlobalCallService.instance.hideIncomingCall();

    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    AppLogger.log(
      'Calling _endCallProperly() from dispose',
      tag: 'CALL_SCREEN',
    );
    _callService?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      AppLogger.log(
        'APP GOING TO BACKGROUND - Call will continue',
        tag: 'CALL_SCREEN',
      );
    } else if (state == AppLifecycleState.detached) {
      _endCallProperly();
    }
  }

  Future<void> _endCallProperly() async {
    if (_sessionId != null && _sessionId! > 0) {
      AppLogger.log(
        'Valid session ID exists, proceeding to end call',
        tag: 'CALL_SCREEN',
      );
      await _callService?.endCall(_sessionId, _callDuration);
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    try {
      final micStatus = await Permission.microphone.request();

      if (micStatus.isGranted) {
        await _initializeCall();
      } else if (micStatus.isDenied) {
        setState(() {
          _callStatus = 'Microphone permission required';
        });
        _showPermissionDialog();
      } else if (micStatus.isPermanentlyDenied) {
        setState(() {
          _callStatus = 'Permission denied';
        });
        _showSettingsDialog();
      }
    } catch (e) {
      AppLogger.error('Permission request failed', error: e, tag: 'CALL');
      setState(() {
        _callStatus = 'Permission error';
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: MuvamTexts.titleMedium18(
          context,
          text: 'Microphone Permission Required',
          isTextWidget: true,
        ),
        content: MuvamTexts.bodyMedium14(
          context,
          text: 'This app needs microphone access to make voice calls.',
          isTextWidget: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: MuvamTexts.button16(
              context,
              text: 'Cancel',
              isTextWidget: true,
              color: AppColors.kGreyColor,
            ),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await _requestPermissionsAndInitialize();
            },
            child: MuvamTexts.button16(
              context,
              text: 'Allow',
              isTextWidget: true,
              color: AppColors.kMainColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: MuvamTexts.titleMedium18(
          context,
          text: 'Permission Required',
          isTextWidget: true,
        ),
        content: MuvamTexts.bodyMedium14(
          context,
          text:
              'Please enable microphone permission in app settings to make calls.',
          isTextWidget: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: MuvamTexts.button16(
              context,
              text: 'Cancel',
              isTextWidget: true,
              color: AppColors.kGreyColor,
            ),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              context.pop();
            },
            child: MuvamTexts.button16(
              context,
              text: 'Open Settings',
              isTextWidget: true,
              color: AppColors.kMainColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCall() async {
    try {
      _callService = CallService();

      final success = await _callService?.initialize();
      if (success != true) {
        AppLogger.error('CallService initialization failed', tag: 'CALL');
        setState(() {
          _callStatus = 'Initialization failed';
        });
        return;
      }

      _callService?.onCallStateChanged = (state) {
        if (!mounted) return;

        setState(() {
          _callStatus = state;

          if (state == 'Connected' || state == 'Connecting...') {
            if (state == 'Connected' && !_isCallActive) {
              _isCallActive = true;
              _startCallTimer();
              _callService?.stopRingtone();
            }
          } else if (state == 'Call ended' || state == 'Call rejected') {
            _isCallActive = false;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                context.pop();
              }
            });
          }
        });
      };

      if (widget.sessionId != null) {
        _sessionId = widget.sessionId;
        _callService?.setIncomingCallContext(_sessionId!, widget.rideId, null);

        GlobalCallService.instance.clearPendingMessages();

        await _callService?.answerCall(_sessionId!, widget.rideId);
      } else {
        final session = await _callService?.initiateCall(widget.rideId);

        if (session != null && session['session_id'] != null) {
          _sessionId = session['session_id'] is int
              ? session['session_id']
              : int.tryParse(session['session_id'].toString());
          AppLogger.log(
            'Call initiated - Session ID: $_sessionId',
            tag: 'CALL',
          );
        } else {
          setState(() {
            _callStatus = 'Call initiation failed';
          });
          return;
        }
      }

      setState(() {
        _callStatus = 'Ringing...';
      });
    } catch (e) {
      AppLogger.error('Failed to initialize call', error: e, tag: 'CALL');
      setState(() {
        _callStatus = 'Call failed';
      });
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService?.toggleMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _callService?.toggleSpeaker(_isSpeakerOn);
  }

  void _endCall() async {
    _callTimer?.cancel();

    await _endCallProperly();

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCallProperly();
        return true;
      },
      child: AppScaffold(
        backgroundColor: AppColors.kWhiteColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
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
                            onTap: () async {
                              await _endCallProperly();
                              context.pop();
                            },
                            child: Icon(
                              Icons.arrow_back,
                              size: 20.sp,
                              color: AppColors.kBlackColor,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            MuvamTexts.titleMedium18(
                              context,
                              text: widget.driverName,
                              isTextWidget: true,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kBlackColor,
                            ),
                            SizedBox(height: 5.h),
                            MuvamTexts.bodyMedium14(
                              context,
                              text: _callStatus,
                              isTextWidget: true,
                              fontWeight: FontWeight.w400,
                              color: _isCallActive
                                  ? Colors.green
                                  : AppColors.kGreyColor,
                            ),
                            if (_callDuration > 0) ...[
                              SizedBox(height: 5.h),
                              MuvamTexts.bodyLarge16(
                                context,
                                text: _formatDuration(_callDuration),
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kBlackColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50.h),
                  Center(
                    child: SizedBox(
                      width: 200.w,
                      height: 200.h,
                      child: CircleAvatar(
                        radius: 100.r,
                        backgroundImage: AssetImage(ConstImages.avatar),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 353.w,
                    height: 72.h,
                    margin: EdgeInsets.only(
                      bottom: 49.h,
                      left: 20.w,
                      right: 20.w,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.kFormFieldColor,
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CallButton(
                          icon: Icons.chat,
                          iconColor: AppColors.kBlackColor,
                          onTap: () async {
                            await _endCallProperly();
                            context.pop();
                          },
                        ),
                        CallButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          iconColor: _isSpeakerOn
                              ? Colors.blue
                              : AppColors.kBlackColor,
                          onTap: _toggleSpeaker,
                        ),
                        CallButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          iconColor: _isMuted
                              ? AppColors.kError
                              : AppColors.kBlackColor,
                          onTap: _toggleMute,
                        ),
                        CallButton(
                          icon: Icons.call_end,
                          iconColor: AppColors.kWhiteColor,
                          onTap: _endCall,
                          isEndCall: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
