import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:provider/provider.dart';

class DrawerItemWidget extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;

  const DrawerItemWidget({
    super.key,
    required this.title,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24.w,
              height: 24.h,
              color: themeManager.getTextColor(context),
            ),
            SizedBox(width: 20.w),
            Text(
              title,
              style: ConstTextStyles.drawerItem.copyWith(
                color: themeManager.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
