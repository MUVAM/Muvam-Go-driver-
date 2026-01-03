import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/wallet_screen.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam_rider/features/referral/presentation/screens/referral_screen.dart';
import 'package:muvam_rider/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:muvam_rider/features/support/presentation/screens/faq_screen.dart';
import 'package:muvam_rider/features/support/presentation/screens/about_us_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer_item_widget.dart';

class DriverAppDrawer extends StatefulWidget {
  final VoidCallback onContactUsTap;

  const DriverAppDrawer({super.key, required this.onContactUsTap});

  @override
  State<DriverAppDrawer> createState() => _DriverAppDrawerState();
}

class _DriverAppDrawerState extends State<DriverAppDrawer> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.toggleTheme();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Drawer(
      backgroundColor: themeManager.getCardColor(context),
      child: Container(
        color: themeManager.getCardColor(context),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 30.h, right: 0.w),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: themeManager.getTextColor(context),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
                  profileProvider.userProfilePhoto.isNotEmpty
                      ? CircleAvatar(
                          radius: 30.r,
                          backgroundImage: NetworkImage(
                            profileProvider.userProfilePhoto,
                          ),
                        )
                      : Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileProvider.userShortName.isNotEmpty
                                ? profileProvider.userShortName
                                : '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: themeManager.getTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My account',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: themeManager.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16.sp,
                                color: themeManager.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            Divider(
              thickness: 1,
              color: themeManager.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
              height: 1,
            ),
            SizedBox(height: 8.h),
            DrawerItemWidget(
              title: 'Wallet',
              iconPath: ConstImages.wallet,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WalletScreen()),
                );
              },
            ),
            DrawerItemWidget(
              title: 'Referral',
              iconPath: ConstImages.referral,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReferralScreen()),
                );
              },
            ),
            DrawerItemWidget(
              title: 'Analytics',
              iconPath: ConstImages.activities,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                );
              },
            ),
            DrawerItemWidget(
              title: 'Contact us',
              iconPath: ConstImages.phoneCall,
              onTap: widget.onContactUsTap,
            ),
            DrawerItemWidget(
              title: 'FAQ',
              iconPath: ConstImages.faq,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaqScreen()),
                );
              },
            ),
            DrawerItemWidget(
              title: 'About',
              iconPath: ConstImages.about,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsScreen()),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.grey.shade700
                          : Color(ConstColors.mainColor),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      'Light mode',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: themeManager.getTextColor(context),
                      ),
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: Color(ConstColors.mainColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
