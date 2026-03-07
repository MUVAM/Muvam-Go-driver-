import 'package:flutter/material.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/provider/connectivity_provider.dart';

class BannerContent extends StatelessWidget {
  final NetworkState state;

  const BannerContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isOffline = state == NetworkState.disconnected;
    final isReconnecting = state == NetworkState.reconnecting;

    final bgColor = isOffline ? const Color(0xFF1C1C1E) : AppColors.kMainColor;

    final icon = isOffline
        ? Icons.wifi_off_rounded
        : isReconnecting
        ? Icons.wifi_rounded
        : Icons.wifi_rounded;

    final message = isOffline
        ? 'No internet connection'
        : isReconnecting
        ? 'Reconnecting…'
        : 'Back online';

    final sub = isOffline
        ? 'Check your network settings'
        : isReconnecting
        ? 'Please wait a moment'
        : 'Your connection was restored';

    return Material(
      color: Colors.transparent,
      child: Container(
        color: bgColor,
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
        child: Row(
          children: [
            if (isReconnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.kWhiteColor),
                ),
              )
            else
              Icon(icon, color: AppColors.kWhiteColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MuvamTexts.bodyMedium14(
                    context,
                    text: message,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kWhiteColor,
                  ),
                  const SizedBox(height: 2),
                  MuvamTexts.bodySmall12(
                    context,
                    text: sub,
                    isTextWidget: true,
                    color: AppColors.kWhiteColor.withOpacity(0.75),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
