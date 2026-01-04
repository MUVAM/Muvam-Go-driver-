import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/services/fcm_token_service.dart';
import 'package:muvam_rider/core/services/enhanced_notification_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/data/providers/rides_provider.dart';
import 'package:muvam_rider/features/analytics/data/providers/earnings_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/data/provider/driver_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/referral/data/providers/referral_provider.dart';
import 'package:muvam_rider/core/services/global_call_service.dart';
import 'package:muvam_rider/shared/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme_manager.dart';
import 'core/services/connectivity_service.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
    AppLogger.log('Firebase initialized successfully', tag: 'FIREBASE');
    await FCMTokenService.initializeFCM();
    EnhancedNotificationService.initEnhancedNotifications();
    // Register FCM background message handler
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.log('FCM background handler registered', tag: 'FIREBASE');
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
        // ChangeNotifierProvider(create: (_) => FCMProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

void _setupGlobalWebSocketHandlerSync() {
  final webSocket = WebSocketService.instance;

  AppLogger.log('DRIVER: Setting up global call handler', tag: 'MAIN_SETUP');

  AppLogger.log(
    'Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  webSocket.addIncomingCallListener((callData) {
    AppLogger.log(
      'DRIVER: INCOMING CALL IN MAIN.DART',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log('Raw call data: $callData', tag: 'DRIVER_MAIN_CALL');

    final callType = callData['type'];
    final messageData = callData['data'];

    AppLogger.log('Call type: $callType', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Message data: $messageData', tag: 'DRIVER_MAIN_CALL');

    if (messageData == null) {
      AppLogger.log('No data in call message!', tag: 'DRIVER_MAIN_CALL');
      return;
    }

    final sessionId = messageData['session_id'];
    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;
    final recipientId = messageData['recipient_id'];

    AppLogger.log('Session ID: $sessionId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Caller Name: $callerName', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Ride ID: $rideId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Recipient ID: $recipientId', tag: 'DRIVER_MAIN_CALL');

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

            AppLogger.log(
              'DRIVER: User accepted call - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              MyApp.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    driverName: callerName,
                    rideId: rideId,
                    sessionId: sessionId,
                  ),
                ),
              );
              AppLogger.log('Navigated to CallScreen', tag: 'DRIVER_MAIN_CALL');
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
  AppLogger.log('Global call handler setup complete', tag: 'MAIN_SETUP');
  AppLogger.log(
    'DO NOT connect WebSocket yet - wait for HomeScreen',
    tag: 'MAIN_SETUP',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    AppLogger.log('MyApp.initState() called', tag: 'APP_INIT');

    GlobalCallService.instance.initialize(MyApp.navigatorKey);

    AppLogger.log('GlobalCallService initialized', tag: 'APP_INIT');
  }

  // Future<void> _initializeFCM() async {
  //   try {
  //     EnhancedNotificationService.initEnhancedNotifications();
  //     AppLogger.log('FCM service initialized in MyApp', tag: 'MAIN');
  //   } catch (e) {
  //     AppLogger.error('Error initializing FCM in MyApp', error: e, tag: 'MAIN');
  //   }
  // }

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
            return MaterialApp(
              navigatorKey: MyApp.navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Muvam',
              theme: themeManager.lightTheme,
              darkTheme: themeManager.darkTheme,
              themeMode: themeManager.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: const ConnectivityWrapper(child: SplashScreen()),
            );
          },
        );
      },
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ConnectivityService().initialize(context);
      }
    });
  }

  @override
  void dispose() {
    ConnectivityService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
