import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _textController;
  late AnimationController _circlePositionController;
  late AnimationController _circleExpandController;
  late AnimationController _textColorController;
  late Animation<Offset> _carSlideAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _circlePositionAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<Color?> _textColorAnimation;

  @override
  void initState() {
    super.initState();

    _carController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _carSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _circlePositionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _circlePositionAnimation =
        Tween<Offset>(begin: const Offset(0, 5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _circlePositionController,
            curve: Curves.easeInOut,
          ),
        );

    _circleExpandController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _circleScaleAnimation = Tween<double>(begin: 0.1, end: 10.0).animate(
      CurvedAnimation(parent: _circleExpandController, curve: Curves.easeInOut),
    );

    _textColorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textColorAnimation =
        ColorTween(
          begin: AppColors.kMainColor,
          end: AppColors.kWhiteColor,
        ).animate(
          CurvedAnimation(parent: _textColorController, curve: Curves.easeIn),
        );

    _carController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _circlePositionController.forward().then((_) {
            _circleExpandController.forward();
            _textColorController.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _checkAuthAndNavigate();
              });
            });
          });
        });
      });
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    AppLogger.log(
      '\n ========== SPLASH SCREEN NAVIGATION CHECK ==========',
      tag: 'SPLASH',
    );

    final isFirstTime = await _isFirstTimeUser();

    if (isFirstTime) {
      await _markAppAsOpened();

      context.goNamedRoute(AppRoutes.onboarding.name);
    } else {
      AppLogger.log('Returning user - checking authentication', tag: 'SPLASH');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final isTokenValid = await authProvider.checkTokenValidity();

      final prefs = await SharedPreferences.getInstance();
      final vehicleSubmitted = prefs.getBool('vehicle_submitted') ?? false;

      if (isTokenValid && vehicleSubmitted == true) {
        AppLogger.log(
          'Both conditions met - checking biometric lock',
          tag: 'SPLASH',
        );

        final biometricService = BiometricAuthService();
        final isBiometricEnabled = await biometricService.isBiometricEnabled();

        if (isBiometricEnabled) {
          AppLogger.log(
            'Biometric lock enabled - prompting user',
            tag: 'SPLASH',
          );
          _promptBiometricAndNavigate(biometricService);
        } else {
          AppLogger.log(
            'Biometric lock not enabled - navigating to Main App',
            tag: 'SPLASH',
          );
          AppLogger.log(
            '========== AUTHENTICATION SUCCESSFUL ==========\n',
            tag: 'SPLASH',
          );
          context.goNamedRoute(AppRoutes.home.name);
        }
      } else {
        AppLogger.log(
          'Conditions not met - navigating to Onboarding',
          tag: 'SPLASH',
        );
        AppLogger.log(
          '========== REDIRECTED TO LOGIN ==========\n',
          tag: 'SPLASH',
        );
        context.goNamedRoute(AppRoutes.onboarding.name);
      }
    }
  }

  void _promptBiometricAndNavigate(BiometricAuthService biometricService) {
    if (!mounted) return;
    context.pushNamedRoute(
      AppRoutes.biometricLock.name,
      extra: {
        'isLoginScreen': true,
        'onAuthenticated': () => context.goNamedRoute(AppRoutes.home.name),
      },
    );
  }

  Future<bool> _isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_opened_app') ?? true;
  }

  Future<void> _markAppAsOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_opened_app', false);
  }

  @override
  void dispose() {
    _carController.dispose();
    _textController.dispose();
    _circlePositionController.dispose();
    _circleExpandController.dispose();
    _textColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: Stack(
        children: [
          Center(
            child: SlideTransition(
              position: _carSlideAnimation,
              child: Image.asset(
                ConstImages.onboardCar1,
                width: 411.w,
                height: 411.h,
              ),
            ),
          ),
          Center(
            child: SlideTransition(
              position: _circlePositionAnimation,
              child: ScaleTransition(
                scale: _circleScaleAnimation,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: const BoxDecoration(
                    color: AppColors.kMainColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _textOpacityAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: AnimatedBuilder(
                  animation: _textColorAnimation,
                  builder: (context, child) {
                    return MuvamTexts.headlineMedium28(
                      context,
                      text: 'MUVAM DRIVER',
                      isTextWidget: true,
                      color: _textColorAnimation.value ?? AppColors.kMainColor,
                      fontWeight: FontWeight.bold,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
