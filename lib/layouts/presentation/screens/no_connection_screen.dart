import 'package:flutter/material.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/layouts/provider/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NoConnectionScreen extends StatefulWidget {
  final Future<void> Function() onRetry;
  final String title;
  final String subtitle;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.title = 'No internet connection',
    this.subtitle =
        "We couldn't load your data. Check your network and try again.",
  });

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await widget.onRetry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.isConnected
                        ? Icons.refresh_rounded
                        : Icons.wifi_off_rounded,
                    size: 38,
                    color: AppColors.kGreyColor,
                  ),
                ),
                const SizedBox(height: 24),
                MuvamTexts.titleMedium18(
                  context,
                  text: provider.isConnected
                      ? 'Something went wrong'
                      : widget.title,
                  isTextWidget: true,
                  center: true,
                  color: const Color(0xFF1C1C1E),
                ),
                const SizedBox(height: 10),
                MuvamTexts.bodyMedium14(
                  context,
                  text: provider.isConnected
                      ? 'An error occurred loading your data.'
                      : widget.subtitle,
                  isTextWidget: true,
                  center: true,
                  color: AppColors.kGreyColor,
                  height: 1.5,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isConnected || _isRetrying
                        ? (_isRetrying ? null : _retry)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kMainColor,
                      foregroundColor: AppColors.kWhiteColor,
                      disabledBackgroundColor: AppColors.kGreyColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.kWhiteColor,
                              ),
                            ),
                          )
                        : MuvamTexts.button16(
                            context,
                            text: 'Try again',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kWhiteColor,
                          ),
                  ),
                ),
                if (!provider.isConnected) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.kGreyColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Waiting for connection…',
                        isTextWidget: true,
                        color: AppColors.kGreyColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
