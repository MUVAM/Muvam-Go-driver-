import 'package:flutter/material.dart';
import 'package:muvam_rider/layouts/presentation/shared/banner_content.dart';
import 'package:muvam_rider/layouts/provider/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NetworkBanner extends StatefulWidget {
  final Widget child;

  const NetworkBanner({super.key, required this.child});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(NetworkState state) {
    if (state == NetworkState.disconnected ||
        state == NetworkState.reconnecting) {
      _controller.forward();
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, child) {
        _sync(provider.state);

        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: BannerContent(state: provider.state),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
