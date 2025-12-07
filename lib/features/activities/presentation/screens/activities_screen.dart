import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/history_item.dart';
import 'package:muvam_rider/features/activities/presentation/widgets/trip_card.dart';
import 'package:muvam_rider/features/trips/presentation/screen/active_trip_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_cancelled_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/history_completed_screen.dart';
import 'package:muvam_rider/features/trips/presentation/screen/trip_details_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ActivitiesScreenState createState() => ActivitiesScreenState();
}

class ActivitiesScreenState extends State<ActivitiesScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 70.h,
            left: 20.w,
            child: Container(
              width: 45.w,
              height: 45.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.r),
              ),
              padding: EdgeInsets.all(10.w),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Positioned(
            top: 140.h,
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
                  Container(
                    width: 0.5.w,
                    height: 28.h,
                    color: Theme.of(context).dividerColor,
                  ),
                  _buildTabItem('Active', 1),
                  Container(
                    width: 0.5.w,
                    height: 28.h,
                    color: Theme.of(context).dividerColor,
                  ),
                  _buildTabItem('History', 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 197.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: SingleChildScrollView(child: _getCurrentTabContent()),
          ),
        ],
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
            border: isSelected
                ? Border.all(color: Theme.of(context).dividerColor, width: 0.5)
                : null,
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
        return TripCard(
          time: '8:00pm',
          date: 'Nov 28, 2025',
          destination: 'Ikeja, Lagos',
          tripId: '#12345',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TripDetailsScreen()),
          ),
        );
      case 1:
        return TripCard(
          time: '8:00pm',
          date: 'Nov 28, 2025',
          destination: 'Ikeja, Lagos',
          tripId: '#12345',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActiveTripScreen()),
          ),
          isActive: true,
        );
      case 2:
        return Column(
          children: [
            HistoryItem(
              time: '8:00pm',
              date: 'Nov 28, 2025',
              destination: 'Ikeja, Lagos',
              isCompleted: true,
              price: '₦12,000',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryCompletedScreen(
                    ride: {
                      'ID': '12345',
                      'Price': '12000',
                      'PickupAddress': 'Sample Pickup Location',
                      'DestAddress': 'Ikeja, Lagos',
                      'PaymentMethod': 'card',
                    },
                    acceptedData: {'tip': 500},
                  ),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            HistoryItem(
              time: '6:30pm',
              date: 'Nov 27, 2025',
              destination: 'Abuja, FCT',
              isCompleted: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryCancelledScreen(),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            HistoryItem(
              time: '2:15pm',
              date: 'Nov 26, 2025',
              destination: 'Port Harcourt, Rivers',
              isCompleted: true,
              price: '₦8,500',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryCompletedScreen(
                    ride: {
                      'ID': '12347',
                      'Price': '8500',
                      'PickupAddress': 'Sample Pickup Location',
                      'DestAddress': 'Port Harcourt, Rivers',
                      'PaymentMethod': 'wallet',
                    },
                    acceptedData: {'tip': 300},
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return TripCard(
          time: '8:00pm',
          date: 'Nov 28, 2025',
          destination: 'Ikeja, Lagos',
          tripId: '#12345',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TripDetailsScreen()),
          ),
        );
    }
  }
}
