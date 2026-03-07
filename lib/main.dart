import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/config/repository/ui_service.dart';
import 'package:muvam_rider/core/config/routes/app_router.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/services/fcm_token_service.dart';
import 'package:muvam_rider/core/services/enhanced_notification_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/data/providers/rides_provider.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/%20delete_account_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/provider/driver_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/referral/data/providers/referral_provider.dart';
import 'package:muvam_rider/core/services/global_call_service.dart';
import 'package:muvam_rider/features/vehicles/data/provider/vehicle_provider.dart';
import 'package:muvam_rider/layouts/presentation/screens/connectivity_wrapper.dart';
import 'package:muvam_rider/layouts/presentation/screens/network_banner.dart';
import 'package:muvam_rider/layouts/provider/connectivity_provider.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme_manager.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
    await FCMTokenService.initializeFCM();
    EnhancedNotificationService.initEnhancedNotifications();
  } catch (e) {
    AppLogger.error(
      'Firebase initialization failed',
      error: e,
      tag: 'FIREBASE',
    );
  }

  final chatProvider = ChatProvider();
  await chatProvider.loadMessages();

  _setupGlobalWebSocketHandlerSync();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => ThemeManager()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => DeleteAccountProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => UIService()),
      ],
      child: const MyApp(),
    ),
  );
}

void _setupGlobalWebSocketHandlerSync() {
  final webSocket = WebSocketService.instance;

  AppLogger.log(
    'Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  webSocket.addIncomingCallListener((callData) {
    AppLogger.log(
      'DRIVER: INCOMING CALL IN MAIN.DART',
      tag: 'DRIVER_MAIN_CALL',
    );

    final callType = callData['type'];
    final messageData = callData['data'];

    if (messageData == null) return;

    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;

    if (callType == 'call_initiate') {
      AppLogger.log(
        'Showing incoming call overlay...',
        tag: 'DRIVER_MAIN_CALL',
      );

      try {
        GlobalCallService.instance.showIncomingCall(
          callData: callData,
          onAccept: (sessionId) async {
            AppLogger.log(
              'DRIVER: Call accepted - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              AppRouter.navigationKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    driverName: callerName,
                    rideId: rideId,
                    sessionId: sessionId,
                  ),
                ),
              );
            } catch (e) {
              AppLogger.error(
                'Failed to navigate to CallScreen',
                error: e,
                tag: 'DRIVER_MAIN_CALL',
              );
              return;
            }
          },
          onReject: (sessionId) async {
            AppLogger.log(
              'DRIVER: Call rejected - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              final callService = CallService();
              try {
                await callService.rejectCall(sessionId);
              } finally {
                callService.dispose();
              }
            } catch (e) {
              AppLogger.log(
                'Error rejecting call: $e',
                tag: 'DRIVER_MAIN_CALL',
              );
            }
          },
        );
      } catch (e) {
        AppLogger.log(
          'Error showing call overlay: $e',
          tag: 'DRIVER_MAIN_CALL',
        );
      }
    } else {
      AppLogger.log(
        'Call type is $callType (not call_initiate), passing to CallService',
        tag: 'DRIVER_MAIN_CALL',
      );

      if (callType == 'call_offer' || callType == 'call_ice_candidate') {
        GlobalCallService.instance.addPendingMessage(callData);
      }
    }
  });

  AppLogger.log(
    'Handler after setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log(
    'DO NOT connect WebSocket yet - wait for HomeScreen',
    tag: 'MAIN_SETUP',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppRouter _appRouter = AppRouter();

  @override
  void initState() {
    super.initState();
    GlobalCallService.instance.initialize(AppRouter.navigationKey);
  }

  @override
  void dispose() {
    GlobalCallService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              routerConfig: _appRouter.routerConfig,
              debugShowCheckedModeBanner: false,
              title: 'Muvam',
              theme: themeManager.lightTheme,
              darkTheme: themeManager.darkTheme,
              themeMode: themeManager.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              builder: (context, child) => NetworkBanner(
                child: ConnectivityWrapper(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
