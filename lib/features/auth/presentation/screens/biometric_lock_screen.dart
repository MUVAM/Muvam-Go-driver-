import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool isLoginScreen;

  const BiometricLockScreen({
    super.key,
    required this.onAuthenticated,
    this.isLoginScreen = false,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;
  bool _authenticationSuccess = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _loadBiometricType() async {
    final type = await _biometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = type;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authenticationSuccess = false;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        reason: widget.isLoginScreen
            ? 'Authenticate to login to MuvamGo Driver'
            : 'Authenticate to unlock MuvamGo Driver',
        biometricOnly: false,
      );

      if (authenticated) {
        setState(() {
          _authenticationSuccess = true;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        _biometricService.clearBackgroundTime();
        widget.onAuthenticated();
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Authentication failed. Please try again.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFaceID = _biometricType == 'Face ID';

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuvamTexts.headlineSmall24(
                  context,
                  text: isFaceID ? 'Place your Head' : 'Place your Finger',
                  isTextWidget: true,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 60.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: isFaceID
                        ? 'Place your head in the middle of the circle to add your face.'
                        : 'Place your finger on the sensor and lift after you feel a vibration',
                    isTextWidget: true,
                    center: true,
                    color: AppColors.kSubtitleColor,
                  ),
                ),
                SizedBox(height: 40.h),
                if (isFaceID)
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticate,
                    child: Container(
                      width: 200.w,
                      height: 260.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(130.w),
                        border: Border.all(
                          color: _authenticationSuccess
                              ? Colors.green
                              : _isAuthenticating
                              ? AppColors.kMainColor
                              : Colors.grey.shade400,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: _isAuthenticating
                            ? const CircularProgressIndicator(
                                color: AppColors.kMainColor,
                                strokeWidth: 3,
                              )
                            : Icon(
                                Icons.face_outlined,
                                size: 80.sp,
                                color: _authenticationSuccess
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticate,
                    child: Container(
                      width: 150.w,
                      height: 150.h,
                      child: _isAuthenticating
                          ? const CircularProgressIndicator(
                              color: AppColors.kMainColor,
                              strokeWidth: 3,
                            )
                          : Image.asset(
                              _authenticationSuccess
                                  ? 'assets/images/fingerGreen.png'
                                  : 'assets/images/fingerGrey.png',
                              width: 150.w,
                              height: 150.h,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                SizedBox(height: 40.h),
                if (!_isAuthenticating && !_authenticationSuccess)
                  TextButton(
                    onPressed: _authenticate,
                    child: MuvamTexts.bodyMedium14(
                      context,
                      text: 'Tap to Authenticate',
                      isTextWidget: true,
                      color: AppColors.kMainColor,
                      fontWeight: FontWeight.w500,
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
