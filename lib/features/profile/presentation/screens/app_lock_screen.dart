import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  late SharedPreferences _prefs;

  bool _isBiometricEnabled = false;
  String _lockTiming = 'immediately';
  bool _isLoading = true;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadSettings();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      _canCheckBiometrics = await auth.canCheckBiometrics;
      _availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException {}
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      _isBiometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
      _lockTiming = _prefs.getString('lock_timing') ?? 'immediately';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await _prefs.setString('lock_timing', _lockTiming);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Biometric authentication is not available on this device',
      );
      return;
    }
    if (value) {
      final result = await context.pushNamed(
        AppRoutes.biometricSetup.name,
        extra: {'onComplete': () => context.pop(true), 'isLoginScreen': false},
      );
      if (result == true && mounted) {
        setState(() => _isBiometricEnabled = true);
        await _saveSettings();
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Biometric authentication enabled successfully',
        );
      }
    } else {
      setState(() => _isBiometricEnabled = false);
      await _saveSettings();
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Biometric authentication disabled',
      );
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(ConstColors.mainColor)),
        ),
      );
    }

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: 'App Lock Settings',
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 33.w),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MuvamTexts.bodyMedium14(
                                context,
                                text: 'Unlock with ${_getBiometricTypeText()}',
                                fontWeight: FontWeight.w600,
                                color: AppColors.kBlackColor,
                              ),
                              SizedBox(height: 8.h),
                              MuvamTexts.bodySmall12(
                                context,
                                text:
                                    'When enabled, you will need to use ${_getBiometricTypeText().toLowerCase()} to open Muvam.',
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Switch(
                          value: _isBiometricEnabled,
                          onChanged: _toggleBiometric,
                          activeColor: Color(ConstColors.mainColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (!_canCheckBiometrics || _availableBiometrics.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: MuvamTexts.bodySmall12(
                              context,
                              text:
                                  'Biometric authentication is not available on this device',
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
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
