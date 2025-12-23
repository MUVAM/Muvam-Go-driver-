import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/services/call_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/data/providers/rides_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/communication/presentation/screens/call_screen.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/data/provider/driver_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/services/globalincomingcall.dart';
import 'package:muvam_rider/shared/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme_manager.dart';
import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load persisted chat messages
  final chatProvider = ChatProvider();
  await chatProvider.loadMessages();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeManager()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
 final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  @override
  void initState() {
    super.initState();
    
    // Initialize global call service
    GlobalCallService.instance.initialize(navigatorKey);
    
    // Setup WebSocket incoming call handler
    _setupGlobalCallHandler();
  }

  void _setupGlobalCallHandler() {
    final webSocket = WebSocketService.instance;
    
    webSocket.onIncomingCall = (callData) {
      AppLogger.log('📞 Global incoming call handler triggered', tag: 'MAIN_APP');
      
      // Show incoming call overlay globally
      GlobalCallService.instance.showIncomingCall(
        callData: callData,
        onAccept: (sessionId) async {
          final callerName = callData['data']?['caller_name'] ?? 'Unknown';
          final rideId = callData['data']?['ride_id'] ?? 0;
          
          // Answer the call via API
          final callService = CallService();
          await callService.answerCall(sessionId);
          
          // Navigate to call screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CallScreen(
                driverName: callerName,
                rideId: rideId,
              ),
            ),
          );
        },
        onReject: (sessionId) async {
          // Reject the call via API
          final callService = CallService();
          await callService.rejectCall(sessionId);
        },
      );
    };
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
                navigatorKey: navigatorKey, // IMPORTANT: Set the navigator key

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
