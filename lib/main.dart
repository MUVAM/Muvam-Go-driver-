import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/activities/data/providers/rides_provider.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/communication/data/providers/chat_provider.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'package:muvam_rider/features/home/data/provider/driver_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/shared/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeManager()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => WithdrawalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
