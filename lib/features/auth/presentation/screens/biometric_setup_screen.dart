import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class BiometricSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isLoginScreen;

  const BiometricSetupScreen({
    super.key,
    required this.onComplete,
    this.isLoginScreen = false,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isScanning = false;
  bool _scanComplete = false;
  String _biometricType = 'Fingerprint';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startBiometricScan();
        }
      });
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

  Future<void> _startBiometricScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final reason = widget.isLoginScreen
          ? 'Authenticate to access Muvam'
          : 'Place your finger on the sensor to set up biometric authentication';

      final authenticated = await _biometricService.authenticate(
        reason: reason,
        biometricOnly: false,
      );

      if (authenticated) {
        await HapticFeedback.heavyImpact();

        if (mounted) {
          setState(() {
            _scanComplete = true;
            _isScanning = false;
          });

          if (widget.isLoginScreen) {
            widget.onComplete();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });

          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted && !_scanComplete) {
            _startBiometricScan();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _proceedToAuthentication() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isFaceID = _biometricType == 'Face ID';

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              MuvamTexts.headlineSmall24(
                context,
                text: isFaceID ? 'Place your face' : 'Place your finger',
                isTextWidget: true,
                center: true,
                color: AppColors.kBlackColor,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: MuvamTexts.bodyLarge16(
                  context,
                  text: isFaceID
                      ? 'Place your face in the middle of the circle and hold still'
                      : 'Place your finger on the sensor and lift after you feel a vibration',
                  isTextWidget: true,
                  center: true,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 60.h),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: isFaceID
                    ? Container(
                        width: 200.w,
                        height: 260.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(130.w),
                          border: Border.all(
                            color: _scanComplete
                                ? Colors.green
                                : _isScanning
                                ? AppColors.kMainColor
                                : Colors.grey.shade400,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.face_outlined,
                            size: 80.sp,
                            color: _scanComplete
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Image.asset(
                        _scanComplete
                            ? 'assets/images/fingerGreen.png'
                            : 'assets/images/fingerGrey.png',
                        width: 208.w,
                        height: 208.h,
                        fit: BoxFit.contain,
                      ),
              ),
              SizedBox(height: 60.h),
              if (_scanComplete)
                GestureDetector(
                  onTap: _proceedToAuthentication,
                  child: Container(
                    width: double.infinity,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: AppColors.kMainColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: MuvamTexts.button16(
                        context,
                        text: 'Done',
                        color: AppColors.kWhiteColor,
                        fontWeight: FontWeight.w600,
                        isTextWidget: true,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
