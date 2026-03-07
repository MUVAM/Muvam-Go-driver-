import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/account_verification_success_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/biometric_lock_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/biometric_setup_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/create_account_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/document_verification_success_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/driver_license_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/kyc_verification_page.dart';
import 'package:muvam_rider/features/auth/presentation/screens/lga_selection_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/otp_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/state_selection_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/vehicle_insurance_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/vehicle_photos_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/vehicle_registration_screen.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/communication/presentation/screens/chat_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/bank_selection_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/how_to_withdraw.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/wallet_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/withdrawal_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/withdrawal_success_screen.dart';
import 'package:muvam_rider/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:muvam_rider/features/profile/presentation/screens/app_lock_screen.dart';
import 'package:muvam_rider/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:muvam_rider/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam_rider/features/profile/presentation/screens/update_location_screen.dart';
import 'package:muvam_rider/features/ratings/presentation/screens/ratings_screen.dart';
import 'package:muvam_rider/features/referral/presentation/referral_rules_screen.dart';
import 'package:muvam_rider/features/referral/presentation/referral_screen.dart';
import 'package:muvam_rider/features/services/presentation/services_screen.dart';
import 'package:muvam_rider/features/support/presentation/about_us_screen.dart';
import 'package:muvam_rider/features/support/presentation/faq_screen.dart';
import 'package:muvam_rider/features/tips/presentation/custom_tip_screen.dart';
import 'package:muvam_rider/features/tips/presentation/tip_screen.dart';
import 'package:muvam_rider/features/trips/presentation/active_trip_screen.dart';
import 'package:muvam_rider/features/trips/presentation/history_cancelled_screen.dart';
import 'package:muvam_rider/features/trips/presentation/history_completed_screen.dart';
import 'package:muvam_rider/features/trips/presentation/trip_details_screen.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/my_cars_screen.dart';
import 'package:muvam_rider/layouts/presentation/screens/coming_soon_screen.dart';
import 'package:muvam_rider/layouts/presentation/screens/onboarding_screen.dart';
import 'package:muvam_rider/layouts/presentation/screens/splash_screen.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigationKey =
      GlobalKey<NavigatorState>();

  static String? _lastKnownRoute;

  BuildContext? get mainBuildContext => navigationKey.currentState?.context;

  static AppRoutes get _getInitialPath {
    if (_lastKnownRoute != null && _lastKnownRoute!.isNotEmpty) {
      for (final route in AppRoutes.values) {
        if (route.urlPath == _lastKnownRoute!) {
          return route;
        }
      }
    }
    return AppRoutes.splash;
  }

  late final GoRouter routerConfig = _buildRouter();

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: navigationKey,
      initialLocation: _getInitialPath.urlPath,
      debugLogDiagnostics: true,
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
      redirect: (context, state) {
        final String? path = state.fullPath;
        if (path != null && path.isNotEmpty && path != '/') {
          _lastKnownRoute = path;
        }
        AppLogger.log('Navigating to: $path', tag: 'ROUTER');
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash.urlPath,
          name: AppRoutes.splash.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const SplashScreen()),
        ),
        GoRoute(
          path: AppRoutes.onboarding.urlPath,
          name: AppRoutes.onboarding.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const OnboardingScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.otp.urlPath,
          name: AppRoutes.otp.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              OtpScreen(phoneNumber: extra['phoneNumber'] as String),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.accountVerificationSuccess.urlPath,
          name: AppRoutes.accountVerificationSuccess.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AccountVerificationSuccessScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.createAccount.urlPath,
          name: AppRoutes.createAccount.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final phoneNumber = extra?['phoneNumber'] as String? ?? '';
            final serviceType = extra?['serviceType'] as String?;
            return _buildSlidePage(
              CreateAccountScreen(
                phoneNumber: phoneNumber,
                serviceType: serviceType,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.kycVerificationPage.urlPath,
          name: AppRoutes.kycVerificationPage.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              KycVerificationPage(
                firstName: extra?['firstName'] as String?,
                lastName: extra?['lastName'] as String?,
                email: extra?['email'] as String?,
                phone: extra?['phone'] as String?,
                dob: extra?['dob'] as String?,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.deleteAccount.urlPath,
          name: AppRoutes.deleteAccount.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const DeleteAccountScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.stateSelection.urlPath,
          name: AppRoutes.stateSelection.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const StateSelectionScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.lgaSelection.urlPath,
          name: AppRoutes.lgaSelection.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              LgaSelectionScreen(
                selectedState: extra['selectedState'] as String,
              ),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.home.urlPath,
          name: AppRoutes.home.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialIndex = extra?['initialIndex'] as int? ?? 0;
            return _buildPlatformPage(
              MainNavigationScreen(initialIndex: initialIndex),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.activeTrip.urlPath,
          name: AppRoutes.activeTrip.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              ActiveTripScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.historyCompleted.urlPath,
          name: AppRoutes.historyCompleted.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              HistoryCompletedScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.historyCancelled.urlPath,
          name: AppRoutes.historyCancelled.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              HistoryCancelledScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.tripDetails.urlPath,
          name: AppRoutes.tripDetails.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              TripDetailsScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.tip.urlPath,
          name: AppRoutes.tip.name,
          pageBuilder: (context, state) {
            return _buildSlidePage(
              const TipScreen(),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.customTip.urlPath,
          name: AppRoutes.customTip.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const CustomTipScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.chat.urlPath,
          name: AppRoutes.chat.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              ChatScreen(
                rideId: extra['rideId'] as int,
                driverName: extra['driverName'] as String,
                driverId: extra['driverId'] as String,
                driverImage: extra['driverImage'] as String?,
                driverPhone: extra['driverPhone'] as String?,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.call.urlPath,
          name: AppRoutes.call.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              CallScreen(
                driverName: extra['driverName'] as String,
                rideId: extra['rideId'] as int,
                sessionId: extra['sessionId'] as int?,
              ),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.profile.urlPath,
          name: AppRoutes.profile.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ProfileScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.editProfile.urlPath,
          name: AppRoutes.editProfile.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const EditProfileScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.biometricLock.urlPath,
          name: AppRoutes.biometricLock.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildPlatformPage(
              BiometricLockScreen(
                onAuthenticated:
                    extra?['onAuthenticated'] as VoidCallback? ?? () {},
                isLoginScreen: extra?['isLoginScreen'] as bool? ?? false,
              ),
              fullscreenDialog: true,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.services.urlPath,
          name: AppRoutes.services.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ServicesScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.comingSoon.urlPath,
          name: AppRoutes.comingSoon.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ComingSoonScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.wallet.urlPath,
          name: AppRoutes.wallet.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const WalletScreen()),
        ),
        GoRoute(
          path: AppRoutes.referral.urlPath,
          name: AppRoutes.referral.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ReferralScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.referralRules.urlPath,
          name: AppRoutes.referralRules.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ReferralRulesScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.aboutUs.urlPath,
          name: AppRoutes.aboutUs.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AboutUsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.withdrawal.urlPath,
          name: AppRoutes.withdrawal.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const WithdrawalScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.withdrawalSuccess.urlPath,
          name: AppRoutes.withdrawalSuccess.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              WithdrawalSuccessScreen(amount: extra?['amount'] as double? ?? 0),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.bankSelection.urlPath,
          name: AppRoutes.bankSelection.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const BankSelectionScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.howToWithdraw.urlPath,
          name: AppRoutes.howToWithdraw.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const HowToWithdraw(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.faq.urlPath,
          name: AppRoutes.faq.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const FaqScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.ratings.urlPath,
          name: AppRoutes.ratings.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const RatingsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.carInformation.urlPath,
          name: AppRoutes.carInformation.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              CarInformationScreen(
                showBackButton: extra?['showBackButton'] as bool? ?? false,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.myCars.urlPath,
          name: AppRoutes.myCars.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const MyCarsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.appLock.urlPath,
          name: AppRoutes.appLock.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AppLockScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.updateLocation.urlPath,
          name: AppRoutes.updateLocation.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const UpdateLocationScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.driverLicense.urlPath,
          name: AppRoutes.driverLicense.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              DriverLicenseScreen(
                token: extra['token'] as String,
                carMake: extra['carMake'] as String,
                carModel: extra['carModel'] as String,
                carYear: extra['carYear'] as String,
                carSeats: extra['carSeats'] as String,
                licenseNumber: extra['licenseNumber'] as String,
                licensePlate: extra['licensePlate'] as String,
                carColor: extra['carColor'] as String,
                isAcEnabled: extra['isAcEnabled'] as bool,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.vehicleInsurance.urlPath,
          name: AppRoutes.vehicleInsurance.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const VehicleInsuranceScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.vehicleRegistration.urlPath,
          name: AppRoutes.vehicleRegistration.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const VehicleRegistrationScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.vehiclePhotos.urlPath,
          name: AppRoutes.vehiclePhotos.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const VehiclePhotosScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.documentVerificationSuccess.urlPath,
          name: AppRoutes.documentVerificationSuccess.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const DocumentVerificationSuccessScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.biometricSetup.urlPath,
          name: AppRoutes.biometricSetup.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              BiometricSetupScreen(
                onComplete: extra?['onComplete'] as VoidCallback? ?? () {},
                isLoginScreen: extra?['isLoginScreen'] as bool? ?? false,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.analytics.urlPath,
          name: AppRoutes.analytics.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AnalyticsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
      ],
    );
  }

  void clearStoredRoute() {
    _lastKnownRoute = null;
  }

  static Page _buildPlatformPage(
    Widget page, {
    LocalKey? key,
    String? name,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (Platform.isIOS) {
      return CupertinoPage(
        key: key,
        name: name,
        child: page,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPage(
      key: key,
      name: name,
      child: page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static Page _buildSlidePage(
    Widget page, {
    LocalKey? key,
    String? name,
    bool maintainState = true,
    bool fullscreenDialog = false,
    _SlideDirection direction = _SlideDirection.fromRight,
  }) {
    return CustomTransitionPage(
      key: key,
      name: name,
      child: page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = switch (direction) {
          _SlideDirection.fromRight => const Offset(1.0, 0.0),
          _SlideDirection.fromLeft => const Offset(-1.0, 0.0),
          _SlideDirection.fromBottom => const Offset(0.0, 1.0),
          _SlideDirection.fromTop => const Offset(0.0, -1.0),
        };
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

enum _SlideDirection { fromRight, fromLeft, fromBottom, fromTop }
