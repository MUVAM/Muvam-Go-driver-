import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/phone_verification_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final hasToken = await authProvider.checkTokenValidity();
    print('HAS TOKEN+++$hasToken');

    if (!hasToken) {
      // No token, go to signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RiderSignupSelectionScreen(),
        ),
      );
      return;
    }

    final isExpired = await authProvider.isSessionExpired();

    if (isExpired) {
      // Session expired, go to phone verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PhoneVerificationScreen()),
      );
    } else {
      // Valid session, update login time and go to home
      await authProvider.updateLastLoginTime();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Image.asset(
            ConstImages.onboardCar1,
            width: 411.w,
            height: 411.h,
          ),
        ),
      ),
    );
  }
}
