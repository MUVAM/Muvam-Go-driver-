import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
        AppLogger.log(
          'New user detected - navigating to Create Account Screen',
        );
        context.pushReplacementNamed(
          AppRoutes.createAccount.name,
          extra: {
            'phoneNumber': widget.phoneNumber,
            'serviceType': widget.serviceType,
          },
        );
      } else {
        final prefs = await SharedPreferences.getInstance();

        final vehicleSubmitted = prefs.getBool('vehicle_submitted') ?? false;

        if (vehicleSubmitted == true) {
          AppLogger.log('Vehicle submitted - navigating to Main App');
          AppLogger.log('========== AUTHENTICATION SUCCESSFUL ==========\n');
          context.pushNamedAndClear(AppRoutes.home.name);
        } else {
          AppLogger.log(
            'Vehicle not submitted - navigating to KYC Verification',
          );
          final userData = authProvider.verifyOtpResponse?['user'];
          context.pushReplacementNamed(
            AppRoutes.kycVerificationPage.name,
            extra: {
              'firstName': userData?['first_name'],
              'lastName': userData?['last_name'],
              'email': userData?['Email'],
              'phone': widget.phoneNumber,
              'dob': userData?['date_of_birth'],
            },
          );
          AppLogger.log(
            '========== REDIRECTED TO KYC VERIFICATION ==========\n',
          );
        }
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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      resizeToAvoidBottomInset: true,
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 60.h),
                    Image.asset(ConstImages.otp, width: 426.w, height: 426.h),
                    MuvamTexts.headlineSmall24(
                      context,
                      text: 'Phone Verification',
                      isTextWidget: true,
                      color: AppColors.kBlackColor,
                    ),
                    SizedBox(height: 2.h),
                    MuvamTexts.bodyMedium14(
                      context,
                      text: 'Enter the 6 digit code sent to you',
                      isTextWidget: true,
                      color: AppColors.kSubtitleColor,
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
                          color: AppColors.kBlackColor,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.kBlackColor,
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
                          color: AppColors.kBlackColor,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.kMainColor,
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
                          color: AppColors.kBlackColor,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.kMainColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (pin) {},
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 9.h),
                            width: 22.w,
                            height: 1,
                            color: AppColors.kMainColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    GestureDetector(
                      onTap: _countdown == 0 ? _resendOtp : null,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Didn\'t receive code? ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.kBlackColor,
                                fontSize: 14.sp,
                              ),
                            ),
                            if (_countdown > 0)
                              TextSpan(
                                text:
                                    '0:${_countdown.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.kMainColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              TextSpan(
                                text: 'Resend',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.kMainColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: 'Edit my number',
                        isTextWidget: true,
                        color: AppColors.kBlackColor,
                        fontWeight: FontWeight.w500,
                        textDecoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    GestureDetector(
                      onTap: isOtpComplete && !_isLoading ? _verifyOtp : null,
                      child: Container(
                        width: double.infinity,
                        height: 47.h,
                        decoration: BoxDecoration(
                          color: isOtpComplete && !_isLoading
                              ? AppColors.kMainColor
                              : AppColors.kFieldColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    color: AppColors.kWhiteColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : MuvamTexts.button16(
                                  context,
                                  text: 'Continue',
                                  color: AppColors.kWhiteColor,
                                  fontWeight: FontWeight.w600,
                                  isTextWidget: true,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DeviceBottomPadding(),
          ],
        ),
      ),
    );
  }
}
