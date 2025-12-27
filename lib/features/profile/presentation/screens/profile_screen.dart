import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/services/ride_tracking_service.dart';
import 'package:muvam_rider/core/services/websocket_service.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/edit_full_name_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/rider_signup_selection_screen.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/profile/presentation/screens/update_location_screen.dart';
import 'package:muvam_rider/features/profile/presentation/widgets/profile_field.dart';
import 'package:muvam_rider/features/ratings/presentation/screens/ratings_screen.dart';
import 'package:muvam_rider/features/vehicles/data/models/vehicle_response.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/vehicle_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  VehicleDetail? primaryVehicle;
  bool isLoadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadPrimaryVehicle();
  }

  Future<void> _loadPrimaryVehicle() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');

    // final token = await TokenManager.getToken();
    if (token == null) return;

    final response = await ApiService.getVehicles(token);
    if (response['success']) {
      final vehicleResponse = VehicleResponse.fromJson(response['data']);
      setState(() {
        primaryVehicle = vehicleResponse.vehicles.firstWhere(
          (v) => v.isDefault,
          orElse: () => vehicleResponse.vehicles.isNotEmpty
              ? vehicleResponse.vehicles.first
              : null as VehicleDetail,
        );
        isLoadingVehicle = false;
      });
    } else {
      setState(() => isLoadingVehicle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.userProfile;

        if (profileProvider.isLoading && user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(ConstColors.mainColor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          ConstImages.back,
                          width: 30.w,
                          height: 30.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'My Account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Stack(
                  children: [
                    profileProvider.userProfilePhoto.isNotEmpty
                        ? CircleAvatar(
                            radius: 40.r,
                            backgroundImage: NetworkImage(
                              profileProvider.userProfilePhoto,
                            ),
                          )
                        : Image.asset(
                            ConstImages.avatar,
                            width: 80.w,
                            height: 80.h,
                          ),
                    Positioned(
                      top: 2.h,
                      left: 51.w,
                      child: Container(
                        width: 18.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120.w,
                  height: 20.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: EdgeInsets.only(right: index < 4 ? 5.w : 0),
                        child: Icon(
                          Icons.star,
                          size: 20.sp,
                          color: index < profileProvider.userRating
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RatingsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View ratings',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileField(
                          label: 'Full name',
                          value: profileProvider.userName,
                          hasEdit: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditFullNameScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Phone number',
                          value: profileProvider.userPhone,
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Date of birth',
                          value: user?.dateOfBirth ?? 'Not set',
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Email address',
                          value: profileProvider.userEmail,
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'City',
                          value: profileProvider.userCity,
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Location',
                          value: 'Update your location',
                          hasEdit: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateLocationScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 30.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Car',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CarInformationScreen(),
                                  ),
                                );
                                _loadPrimaryVehicle();
                              },
                              child: Text(
                                '+ Add another vehicle',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.32,
                                  color: Color(ConstColors.mainColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.h),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleSelectionScreen(),
                              ),
                            );
                            _loadPrimaryVehicle();
                          },
                          child: Container(
                            width: 353.w,
                            decoration: BoxDecoration(
                              color: Color(0xFFF7F9F8),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 15.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (isLoadingVehicle)
                                        SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(ConstColors.mainColor),
                                          ),
                                        )
                                      else if (primaryVehicle?.primaryPhoto !=
                                          null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                          child: Image.network(
                                            primaryVehicle!.primaryPhoto!.url,
                                            width: 40.w,
                                            height: 40.h,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) =>
                                                    Image.asset(
                                                      ConstImages.car,
                                                      width: 20.w,
                                                      height: 20.h,
                                                    ),
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          ConstImages.car,
                                          width: 20.w,
                                          height: 20.h,
                                        ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Active car',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (primaryVehicle != null)
                                              Text(
                                                primaryVehicle!.displayName,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16.sp,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Container(
                          width: 353.w,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: GestureDetector(
                            onTap: () => _showLogoutSheet(context),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeleteAccountScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          color: Colors.white,
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
            Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Are you sure you want to log out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Close the bottom sheet first
                      Navigator.pop(context);

                      // Perform logout
                      await _performLogout(context);
                    },
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(0xFFB1B1B1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Center(
                        child: Text(
                          'Log out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Center(
                        child: Text(
                          'Go Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Logout from providers
      if (context.mounted) {
        await context.read<AuthProvider>().logout();
        await context.read<ProfileProvider>().clearProfile();
      }

      // Stop ride tracking
      RideTrackingService.stopTracking();

      // Disconnect WebSocket
      WebSocketService.instance.disconnect();

      // Navigate to rider selection screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const RiderSignupSelectionScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, try to navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const RiderSignupSelectionScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}
