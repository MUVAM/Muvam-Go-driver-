import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'create_account_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  Timer? _timer;
  int _countdown = 20;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    for (int i = 0; i < otpControllers.length; i++) {
      otpControllers[i].addListener(() {
        setState(() {});
      });
    }
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
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get isOtpComplete {
    return otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _verifyOtp() async {
    String otp = otpControllers.map((controller) => controller.text).join();

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(otp, widget.phoneNumber);

    setState(() => _isLoading = false);

    if (success) {
      if (authProvider.isNewUser) {
        // New user - go to create account
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateAccountScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      } else {
        // Existing user - go to home
        await authProvider.updateLastLoginTime();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Invalid OTP')),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(widget.phoneNumber);

    setState(() {
      _isResending = false;
      _countdown = 20;
    });

    if (success) {
      startTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP sent successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to resend OTP'),
        ),
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
                    // SizedBox(height: 30.h),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45.w,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: otpControllers[index].text.isNotEmpty
                                      ? Color(ConstColors.mainColor)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(ConstColors.mainColor),
                                  width: 2,
                                ),
                              ),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              if (value.length > 1) {
                                otpControllers[index].text = value.substring(
                                  value.length - 1,
                                );
                                otpControllers[index]
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: otpControllers[index].text.length,
                                  ),
                                );
                              }
                              if (value.isNotEmpty && index < 5) {
                                focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                focusNodes[index - 1].requestFocus();
                              }
                            },
                            onTap: () {
                              otpControllers[index].selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: otpControllers[index].text.length,
                                    ),
                                  );
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 30.h),
                    _countdown > 0
                        ? Text(
                            'Didn\'t receive code? Resend code in: 0:${_countdown.toString().padLeft(2, '0')}',
                            style: ConstTextStyles.lightSubtitle,
                          )
                        : GestureDetector(
                            onTap: _isResending ? null : _resendOtp,
                            child: _isResending
                                ? CircularProgressIndicator(
                                    color: Color(ConstColors.mainColor),
                                  )
                                : Text(
                                    'Resend code',
                                    style: TextStyle(
                                      color: Color(ConstColors.mainColor),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                      onTap: (isOtpComplete && !_isLoading) ? _verifyOtp : null,
                      child: Container(
                        width: 353.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isOtpComplete
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
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
