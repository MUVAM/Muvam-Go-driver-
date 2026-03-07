import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/ride_tracking_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer_item_widget.dart';

class DriverAppDrawer extends StatefulWidget {
  final VoidCallback onContactUsTap;
  final void Function(int index)? onNavigateToTab;

  const DriverAppDrawer({
    super.key,
    required this.onContactUsTap,
    this.onNavigateToTab,
  });

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: themeManager.getCardColor(context),
      child: Container(
        color: themeManager.getCardColor(context),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 20.h, right: 0.w),
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
                        context.pop();
                        context.pushNamed(AppRoutes.profile.name);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profileProvider.userShortName.isNotEmpty
                                      ? profileProvider.userShortName
                                      : '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppSpacings.k22,
                                    color: themeManager.getTextColor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MuvamTexts.bodyMedium14(
                                context,
                                text: 'My account',
                                isTextWidget: true,
                                fontWeight: FontWeight.w400,
                                color: AppColors.kFieldColor,
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
            SizedBox(height: 24.h),
            Divider(
              thickness: 1,
              color: themeManager.isDarkMode
                  ? Colors.grey.shade700
                  : const Color(0xFFEEEEEE),
              height: 1,
            ),
            DrawerItemWidget(
              title: 'Wallet',
              iconPath: ConstImages.walletSolid,
              onTap: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                } else {
                  context.pop();
                  context.goNamed(
                    AppRoutes.home.name,
                    extra: {'initialIndex': 2},
                  );
                }
              },
            ),
            DrawerItemWidget(
              title: 'Referral',
              iconPath: ConstImages.settings,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.referral.name);
              },
            ),
            DrawerItemWidget(
              title: 'Analytics',
              iconPath: ConstImages.settings,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.analytics.name);
              },
            ),
            DrawerItemWidget(
              title: 'Contact us',
              iconPath: ConstImages.callIcon,
              onTap: widget.onContactUsTap,
            ),
            DrawerItemWidget(
              title: 'FAQ',
              iconPath: ConstImages.questionCircle,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.faq.name);
              },
            ),
            DrawerItemWidget(
              title: 'About',
              iconPath: ConstImages.book,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.aboutUs.name);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.grey.shade700
                          : AppColors.kMainColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.wb_sunny_outlined,
                      color: AppColors.kWhiteColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: MuvamTexts.titleSmall14(
                      context,
                      text: 'Light mode',
                      isTextWidget: true,
                      fontSize: AppSpacings.k18.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: AppColors.kMainColor,
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showLogoutSheet(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showLogoutSheet(context),
                      child: SvgPicture.asset(
                        ConstImages.logout,
                        width: 24.w,
                        height: 24.h,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFEF5350),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DeviceBottomPadding(),
          ],
        ),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
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
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            MuvamTexts.titleMedium18(
              context,
              text: 'Log Out',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
            SizedBox(height: 20.h),
            MuvamTexts.bodyMedium14(
              context,
              text: 'Are you sure you want to log out of your account?',
              isTextWidget: true,
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
              center: true,
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      context.pop();
                      await _performLogout(context);
                    },
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kGreyColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Log out',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Go Back',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      RideTrackingService.stopTracking();

      WebSocketService.instance.disconnect();

      if (context.mounted) {
        await context.read<AuthProvider>().logout();
        await context.read<ProfileProvider>().clearProfile();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('vehicle_submitted');

      if (context.mounted) {
        context.pushReplacementNamed(AppRoutes.onboarding.name);
      }
    } catch (e) {
      if (context.mounted) {
        context.pushReplacementNamed(AppRoutes.onboarding.name);
      }
    }
  }
}
