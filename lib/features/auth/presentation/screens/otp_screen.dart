import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'create_account_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? serviceType;
  const OtpScreen({super.key, required this.phoneNumber, this.serviceType});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  Timer? _timer;
  int _countdown = 20;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    pinController.addListener(() {
      setState(() {});
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool get isOtpComplete {
    return pinController.text.length == 6;
  }

  Future<void> _verifyOtp() async {
    final otpCode = pinController.text;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(otpCode, widget.phoneNumber);

    setState(() => _isLoading = false);

    if (success) {
      final userRole = authProvider.verifyOtpResponse?['user']?['Role'];
      if (userRole != null && userRole != 'driver') {
        CustomFlushbar.showError(
          context: context,
          message:
              'You cannot log in with a passenger account in the driver app',
        );
        return;
      }

      if (authProvider.isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAccountScreen(
              phoneNumber: widget.phoneNumber,
              serviceType: widget.serviceType,
            ),
          ),
        );
      } else {
        await authProvider.updateLastLoginTime();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
          (route) => false,
        );
      }
    } else {
      CustomFlushbar.showError(
        context: context,
        message: authProvider.errorMessage ?? 'Invalid OTP',
      );
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(widget.phoneNumber);

    if (success) {
      setState(() {
        _countdown = 20;
      });
      startTimer();
      CustomFlushbar.showOtpSuccess(
        context: context,
        message: 'OTP sent successfully',
      );
    } else {
      CustomFlushbar.showError(
        context: context,
        message: authProvider.errorMessage ?? 'Failed to resend OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                ConstImages.onboardBackground,
                height: 353.h,
                width: 393.w,
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 60.h),
                    Image.asset(ConstImages.otp, width: 426.w, height: 426.h),
                    Text(
                      'Phone Verification',
                      style: ConstTextStyles.boldTitle,
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Enter the 6 digit code sent to you',
                      style: ConstTextStyles.lightSubtitle,
                    ),
                    SizedBox(height: 42.h),
                    Pinput(
                      controller: pinController,
                      focusNode: focusNode,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(ConstColors.mainColor),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      submittedPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(ConstColors.mainColor),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (pin) {
                        // Auto-submit when OTP is complete (optional)
                      },
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 9.h),
                            width: 22.w,
                            height: 1,
                            color: Color(ConstColors.mainColor),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    GestureDetector(
                      onTap: _countdown == 0 ? _resendOtp : null,
                      child: Text(
                        _countdown > 0
                            ? 'Didn\'t receive code? Resend code in: 0:${_countdown.toString().padLeft(2, '0')}'
                            : 'Resend code',
                        style: _countdown == 0
                            ? TextStyle(
                                color: Color(ConstColors.mainColor),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              )
                            : ConstTextStyles.lightSubtitle,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Edit my number',
                        style: TextStyle(
                          color: Color(ConstColors.mainColor),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    GestureDetector(
                      onTap: isOtpComplete && !_isLoading ? _verifyOtp : null,
                      child: Container(
                        width: 353.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isOtpComplete && !_isLoading
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
