import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/wallet_screen.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:muvam_rider/features/home/presentation/widgets/driver_app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  DateTime? _lastBackPress;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
    HomeScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
    const ActivitiesScreen(),
    const WalletScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _showContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MuvamTexts.titleMedium18(
                  context,
                  text: 'Contact us',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Image.asset(
                ConstImages.phoneCall,
                width: 22.w,
                height: 22.h,
              ),
              title: MuvamTexts.bodyLarge16(
                context,
                text: 'Via Call',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
                color: AppColors.kBlackColor,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: AppColors.kGreyColor,
              ),
              onTap: () async {
                Navigator.pop(context);
                final Uri phoneUri = Uri(scheme: 'tel', path: '07032992768');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  if (mounted) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Could not open phone dialer',
                    );
                  }
                }
              },
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              leading: Image.asset(
                ConstImages.whatsapp,
                width: 22.w,
                height: 22.h,
              ),
              title: MuvamTexts.bodyLarge16(
                context,
                text: 'Via WhatsApp',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
                color: AppColors.kBlackColor,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: AppColors.kGreyColor,
              ),
              onTap: () async {
                context.pop();
                final Uri whatsappUri = Uri.parse(
                  'https://wa.me/2347032992768',
                );
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(
                    whatsappUri,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  if (mounted) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Could not open WhatsApp',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            CustomFlushbar.showInfo(
              context: context,
              message: 'Press back again to exit',
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DriverAppDrawer(
          onContactUsTap: _showContactBottomSheet,
          onNavigateToTab: (index) {
            _scaffoldKey.currentState?.closeDrawer();
            setState(() => _currentIndex = index);
          },
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.kWhiteColor,
          selectedItemColor: AppColors.kMainColor,
          unselectedItemColor: AppColors.kGreyColor,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Consumer<RequestProvider>(
                builder: (context, requestProvider, child) {
                  final count =
                      requestProvider.activeRides.length +
                      requestProvider.prebookedRides.length;

                  return Stack(
                    children: [
                      Image.asset(
                        ConstImages.requests,
                        width: 24.w,
                        height: 24.h,
                        color: _currentIndex == 1
                            ? AppColors.kMainColor
                            : AppColors.kGreyColor,
                      ),
                      if (count > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.kFailureColor,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: AppColors.kWhiteColor,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ConstImages.wallet,
                width: 24.w,
                height: 24.h,
                color: _currentIndex == 2
                    ? AppColors.kMainColor
                    : AppColors.kGreyColor,
              ),
              label: 'Earnings',
            ),
          ],
        ),
      ),
    );
  }
}
