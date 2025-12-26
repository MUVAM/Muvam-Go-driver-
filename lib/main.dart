import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/services/call_service.dart';
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
import 'package:muvam_rider/features/services/globalincomingcall.dart';
import 'package:muvam_rider/shared/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';

import 'core/constants/theme_manager.dart';
import 'core/utils/app_logger.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Load persisted chat messages
//   final chatProvider = ChatProvider();
//   await chatProvider.loadMessages();

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => ThemeManager()),
//         ChangeNotifierProvider(create: (context) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => WalletProvider()),
//         ChangeNotifierProvider(create: (_) => RidesProvider()),
//         ChangeNotifierProvider.value(value: chatProvider),
//         ChangeNotifierProvider(create: (context) => DriverProvider()),
//         ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
//         ChangeNotifierProvider(create: (_) => ProfileProvider()),
//         ChangeNotifierProvider(create: (_) => RequestProvider()),
//         ChangeNotifierProvider(create: (_) => EarningsProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   @override
//   void initState() {
//     super.initState();

//     // Initialize global call service
//     GlobalCallService.instance.initialize(navigatorKey);

//     // Setup WebSocket incoming call handler
//     _setupGlobalCallHandler();
//   }

//   void _setupGlobalCallHandler() {
//     final webSocket = WebSocketService.instance;

//     webSocket.onIncomingCall = (callData) {
//       AppLogger.log('📞 Global incoming call handler triggered', tag: 'MAIN_APP');

//       // Show incoming call overlay globally
//       GlobalCallService.instance.showIncomingCall(
//         callData: callData,
//         onAccept: (sessionId) async {
//           final callerName = callData['data']?['caller_name'] ?? 'Unknown';
//           final rideId = callData['data']?['ride_id'] ?? 0;

//           // Answer the call via API
//           final callService = CallService();
//           await callService.answerCall(sessionId);

//           // Navigate to call screen
//           navigatorKey.currentState?.push(
//             MaterialPageRoute(
//               builder: (context) => CallScreen(
//                 driverName: callerName,
//                 rideId: rideId,
//               ),
//             ),
//           );
//         },
//         onReject: (sessionId) async {
//           // Reject the call via API
//           final callService = CallService();
//           await callService.rejectCall(sessionId);
//         },
//       );
//     };
//   }

//   @override
//   void dispose() {
//     GlobalCallService.instance.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeManager>(
//       builder: (context, themeManager, child) {
//         return ScreenUtilInit(
//           designSize: const Size(393, 852),
//           minTextAdapt: true,
//           splitScreenMode: true,
//           builder: (context, child) {
//             return MaterialApp(
//                 navigatorKey: navigatorKey, // IMPORTANT: Set the navigator key

//               debugShowCheckedModeBanner: false,
//               title: 'Muvam',
//               theme: themeManager.lightTheme,
//               darkTheme: themeManager.darkTheme,
//               themeMode: themeManager.isDarkMode
//                   ? ThemeMode.dark
//                   : ThemeMode.light,
//               home: const SplashScreen(),
//             );
//           },
//         );
//       },
//     );
//   }
// }

//FOR DRIVER - Fixed main.dart with proper initialization order
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted chat messages
  final chatProvider = ChatProvider();
  await chatProvider.loadMessages();

  // CRITICAL: Setup WebSocket handler IMMEDIATELY before anything else
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
      ],
      child: const MyApp(),
    ),
  );
}

// IMPORTANT: This must be synchronous, not async
void _setupGlobalWebSocketHandlerSync() {
  // Get WebSocket instance WITHOUT connecting
  final webSocket = WebSocketService.instance;

  AppLogger.log(
    '🚀 ═══════════════════════════════════════',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('🚀 DRIVER: Setting up global call handler', tag: 'MAIN_SETUP');
  AppLogger.log(
    '🚀 ═══════════════════════════════════════',
    tag: 'MAIN_SETUP',
  );

  // Check if handler already exists
  AppLogger.log(
    '📋 Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  // Set handler BEFORE any connection attempt
  // Set handler BEFORE any connection attempt
  webSocket.addIncomingCallListener((callData) {
    AppLogger.log(
      '📞 ═══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      '📞 DRIVER: INCOMING CALL IN MAIN.DART',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      '📞 ═══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log('📞 Raw call data: $callData', tag: 'DRIVER_MAIN_CALL');

    final callType = callData['type'];
    final messageData = callData['data'];

    AppLogger.log('📞 Call type: $callType', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Message data: $messageData', tag: 'DRIVER_MAIN_CALL');

    if (messageData == null) {
      AppLogger.log('❌ No data in call message!', tag: 'DRIVER_MAIN_CALL');
      return;
    }

    final sessionId = messageData['session_id'];
    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;
    final recipientId = messageData['recipient_id'];

    AppLogger.log('📞 Session ID: $sessionId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Caller Name: $callerName', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Ride ID: $rideId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Recipient ID: $recipientId', tag: 'DRIVER_MAIN_CALL');

    // Only show for call_initiate
    if (callType == 'call_initiate') {
      AppLogger.log(
        '✅ Showing incoming call overlay...',
        tag: 'DRIVER_MAIN_CALL',
      );

      try {
        // Show incoming call overlay globally
        GlobalCallService.instance.showIncomingCall(
          callData: callData,
          onAccept: (sessionId) async {
            AppLogger.log(
              '✅ DRIVER: Call accepted - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            // Answer the call logic
            AppLogger.log(
              '✅ DRIVER: User accepted call - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            // 1. Navigate to Call Screen IMMEDIATELY (Optimistic UI)
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
              AppLogger.log(
                '✅ Navigated to CallScreen',
                tag: 'DRIVER_MAIN_CALL',
              );
            } catch (e) {
              AppLogger.error(
                '❌ Failed to navigate to CallScreen',
                error: e,
                tag: 'DRIVER_MAIN_CALL',
              );
              return; // If navigation fails, don't proceed
            }

            // The CallScreen will handle answering the call with its initialized CallService
          },
          onReject: (sessionId) async {
            AppLogger.log(
              '❌ DRIVER: Call rejected - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              // Reject the call via API
              final callService = CallService();
              // Do NOT call initialize() here
              try {
                await callService.rejectCall(sessionId);
              } finally {
                callService.dispose();
              }
            } catch (e) {
              AppLogger.log(
                '❌ Error rejecting call: $e',
                tag: 'DRIVER_MAIN_CALL',
              );
            }
          },
        );
      } catch (e) {
        AppLogger.log(
          '❌ Error showing call overlay: $e',
          tag: 'DRIVER_MAIN_CALL',
        );
      }
    } else {
      AppLogger.log(
        'ℹ️ Call type is $callType (not call_initiate), passing to CallService',
        tag: 'DRIVER_MAIN_CALL',
      );

      // Buffer WebRTC messages that might arrive before CallScreen is ready
      if (callType == 'call_offer' || callType == 'call_ice_candidate') {
        GlobalCallService.instance.addPendingMessage(callData);
      }
    }
  });

  // Verify handler was set
  AppLogger.log(
    '📋 Handler after setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('✅ Global call handler setup complete', tag: 'MAIN_SETUP');
  AppLogger.log(
    '⚠️ DO NOT connect WebSocket yet - wait for HomeScreen',
    tag: 'MAIN_SETUP',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Make navigator key static so it can be accessed from main()
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    AppLogger.log('🎬 MyApp.initState() called', tag: 'APP_INIT');

    // Initialize global call service with navigator key
    GlobalCallService.instance.initialize(MyApp.navigatorKey);

    AppLogger.log('✅ GlobalCallService initialized', tag: 'APP_INIT');
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
            return MaterialApp(
              navigatorKey: MyApp.navigatorKey, // Use static key
              debugShowCheckedModeBanner: false,
              title: 'Muvam',
              theme: themeManager.lightTheme,
              darkTheme: themeManager.darkTheme,
              themeMode: themeManager.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
