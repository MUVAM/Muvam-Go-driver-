import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/profile/presentation/screens/app_lock_settings_screen.dart';
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
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'My account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 100.w,
                              height: 100.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0E0E0),
                              ),
                              child: profileProvider.userProfilePhoto.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileProvider.userProfilePhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Color(0xFFE0E0E0),
                                              );
                                            },
                                      ),
                                    )
                                  : Container(),
                            ),
                            Positioned(
                              bottom: 60,
                              right: 0,
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                decoration: BoxDecoration(
                                  color: Color(ConstColors.mainColor),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20.sp,
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
                                padding: EdgeInsets.only(
                                  right: index < 4 ? 5.w : 0,
                                ),
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
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RatingsScreen(),
                              ),
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
                        SizedBox(height: 32.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileField(
                                label: 'Full name',
                                value: profileProvider.userName,
                                hasEdit: false,
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Phone number',
                                value: profileProvider.userPhone,
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Date of birth',
                                value: user?.dateOfBirth ?? 'Not set',
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Email address',
                                value: profileProvider.userEmail,
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'State',
                                value: profileProvider.userCity,
                              ),
                              SizedBox(height: 24.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      builder: (context) =>
                                          VehicleSelectionScreen(),
                                    ),
                                  );
                                  _loadPrimaryVehicle();
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF7F9F8),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 15.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            if (isLoadingVehicle)
                                              SizedBox(
                                                width: 20.w,
                                                height: 20.h,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(
                                                        ConstColors.mainColor,
                                                      ),
                                                    ),
                                              )
                                            else if (primaryVehicle
                                                    ?.primaryPhoto !=
                                                null)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                                child: Image.network(
                                                  primaryVehicle!
                                                      .primaryPhoto!
                                                      .url,
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
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (primaryVehicle != null)
                                                    Text(
                                                      primaryVehicle!
                                                          .displayName,
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                              // ProfileField(
                              //   label: 'Location',
                              //   value: 'Update your location',
                              //   hasEdit: true,
                              //   onTap: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => UpdateLocationScreen(),
                              //       ),
                              //     );
                              //   },
                              // ),
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AppLockSettingsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.sp),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48.w,
                                        height: 48.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                            ConstColors.mainColor,
                                          ).withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          color: Color(ConstColors.mainColor),
                                          size: 28.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Set up biometrics',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'Secure your app with fingerprint \nor face unlock',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF9E9E9E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // SizedBox(height: 24.h),
                              // GestureDetector(
                              //   onTap: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => EditProfileScreen(),
                              //       ),
                              //     );
                              //   },
                              //   child: Container(
                              //     width: double.infinity,
                              //     height: 56.h,
                              //     decoration: BoxDecoration(
                              //       color: Color(ConstColors.mainColor),
                              //       borderRadius: BorderRadius.circular(12.r),
                              //     ),
                              //     child: Center(
                              //       child: Text(
                              //         'Edit profile',
                              //         style: TextStyle(
                              //           fontFamily: 'Inter',
                              //           color: Colors.white,
                              //           fontSize: 16.sp,
                              //           fontWeight: FontWeight.w600,
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
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
}
