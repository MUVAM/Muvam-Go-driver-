import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/biometric_auth_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/biometric_lock_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
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
  late Animation<Offset> _carSlideAnimation;
  late Animation<Offset> _textSlideAnimation;
  bool _showText = false;

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
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _textSlideAnimation =
        Tween<Offset>(
          begin: const Offset(1.5, 0),
          end: const Offset(-1.5, 0),
        ).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
        );

    // Start car animation, then text animation, then navigate
    _carController.forward().then((_) {
      setState(() {
        _showText = true;
      });
      _textController.forward().then((_) {
        _checkAuthAndNavigate();
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
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Car animation
            SlideTransition(
              position: _carSlideAnimation,
              child: Image.asset(
                ConstImages.onboardCar1,
                width: 411.w,
                height: 411.h,
              ),
            ),
            // Text animation - only shows after car animation completes
            if (_showText)
              SlideTransition(
                position: _textSlideAnimation,
                child: Text(
                  'MUVAM DRIVER',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
