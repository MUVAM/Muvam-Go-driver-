import 'package:flutter/cupertino.dart';
import 'package:muvam_rider/core/config/repository/platform_service.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/enum/app_plat_form.dart';

class DeviceBottomPadding extends StatelessWidget {
  const DeviceBottomPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (() {
        final platform = AppPlatformService.getPlatform;
        final height = MediaQuery.viewPaddingOf(context).bottom;

        return switch (platform) {
          AppPlatform.ios => height + (AppSpacings.k24 * 2),
          _ => height + (AppSpacings.k24 * 1.5),
        };
      })(),
    );
  }
}
