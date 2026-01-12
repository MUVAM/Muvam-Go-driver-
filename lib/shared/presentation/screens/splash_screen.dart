import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/biometric_lock_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:muvam_rider/shared/presentation/screens/onboarding_screen.dart';
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

    // Car animation controller
    _carController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _carSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

    // Text animation controller
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

    // Circle position animation controller (moves from bottom to center)
    _circlePositionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _circlePositionAnimation =
        Tween<Offset>(
          begin: const Offset(0, 5), // Start from bottom
          end: Offset.zero, // Move to center
        ).animate(
          CurvedAnimation(
            parent: _circlePositionController,
            curve: Curves.easeInOut,
          ),
        );

    // Circle expand animation controller (expands to fill screen)
    _circleExpandController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _circleScaleAnimation =
        Tween<double>(
          begin: 0.1, // Start small
          end: 10.0, // Expand to fill screen
        ).animate(
          CurvedAnimation(
            parent: _circleExpandController,
            curve: Curves.easeInOut,
          ),
        );

    // Text color animation controller (changes from green to white)
    _textColorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textColorAnimation =
        ColorTween(
          begin: Color(ConstColors.mainColor),
          end: Colors.white,
        ).animate(
          CurvedAnimation(parent: _textColorController, curve: Curves.easeIn),
        );

    // Start car animation, then text animation, then circle animations
    _carController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          // Start circle position animation
          _circlePositionController.forward().then((_) {
            // Start circle expand and text color change simultaneously
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(
      context,
      listen: false,
    );

    final hasToken = await authProvider.checkTokenValidity();
    AppLogger.log('HAS TOKEN+++$hasToken');

    if (!hasToken) {
      // Check if this is the first time the user is opening the app
      final isFirstTime = await _isFirstTimeUser();

      if (isFirstTime) {
        // First-time user: show rider selection screen
        await _markAppAsOpened();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RiderSignupSelectionScreen(),
          ),
        );
      } else {
        // Returning user without token: show phone number input screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
      return;
    }

    final isExpired = await authProvider.isSessionExpired();

    if (isExpired) {
      // Session expired: show phone number input screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      AppLogger.log('fetch the user bank....');
      withdrawalProvider.fetchBanks();
      await authProvider.updateLastLoginTime();

      final biometricService = BiometricAuthService();
      final isBiometricEnabled = await biometricService.isBiometricEnabled();

      if (isBiometricEnabled && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricLockScreen(
              isLoginScreen: true,
              onAuthenticated: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainNavigationScreen(),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Car animation
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
          // Green circle animation (behind text)
          Center(
            child: SlideTransition(
              position: _circlePositionAnimation,
              child: ScaleTransition(
                scale: _circleScaleAnimation,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Text animation with color change
          Center(
            child: FadeTransition(
              opacity: _textOpacityAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: AnimatedBuilder(
                  animation: _textColorAnimation,
                  builder: (context, child) {
                    return Text(
                      'MUVAM DRIVER',
                      style: TextStyle(
                        color:
                            _textColorAnimation.value ??
                            Color(ConstColors.mainColor),
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                      ),
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
