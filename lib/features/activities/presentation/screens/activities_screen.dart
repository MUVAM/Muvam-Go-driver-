import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/activities/data/providers/request_provider.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/active_tab.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/history_tab.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/orders_tab.dart';
import 'package:provider/provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ActivitiesScreenState createState() => ActivitiesScreenState();
}

class ActivitiesScreenState extends State<ActivitiesScreen>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<RequestProvider>().stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = Provider.of<RequestProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.resumed:
        provider.resumePolling();
        break;
      case AppLifecycleState.paused:
        provider.pausePolling();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F9F8),
      body: Stack(
        children: [
          Positioned(
            top: 70.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: const Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildTabItem('Orders', 0),
                  _buildDivider(0),
                  _buildTabItem('Active', 1),
                  _buildDivider(1),
                  _buildTabItem('History', 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 110.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: _getCurrentTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(int dividerIndex) {
    final bool shouldHide =
        _selectedTabIndex == dividerIndex ||
        _selectedTabIndex == dividerIndex + 1;

    return Opacity(
      opacity: shouldHide ? 0.0 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 7.h),
        width: 0.5.w,
        height: 18.h,
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          width: 116.33.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return OrdersTab();
      case 1:
        return ActiveTab();
      case 2:
        return HistoryTab();
      default:
        return OrdersTab();
    }
  }
}
