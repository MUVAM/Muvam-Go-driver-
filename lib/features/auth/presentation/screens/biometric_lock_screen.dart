import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';

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

        // Show success state briefly before navigating
        await Future.delayed(Duration(milliseconds: 500));

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // 'MuvamGo Driver is Locked',

                      isFaceID
                      ? 'Place your Head'
                      : 'Place your Finger',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
               
                SizedBox(height: 60.h),

                // Instruction text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    isFaceID
                        ? 'Place your head in the middle of the circle to add your face.'
                        : 'Place your finger on the sensor and lift after you feel a vibration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 40.h),

                // Biometric display
                if (isFaceID)
                  // Face ID - Oval frame
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
                              ? Color(ConstColors.mainColor)
                              : Colors.grey.shade400,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: _isAuthenticating
                            ? CircularProgressIndicator(
                                color: Color(ConstColors.mainColor),
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
                  // Fingerprint - Image display
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticate,
                    child: Container(
                      width: 150.w,
                      height: 150.h,
                      child: _isAuthenticating
                          ? CircularProgressIndicator(
                              color: Color(ConstColors.mainColor),
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
                    child: Text(
                      'Tap to Authenticate',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(ConstColors.mainColor),
                      ),
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
