import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/profile/presentation/widgets/profile_field.dart';
import 'package:muvam_rider/features/vehicles/data/models/vehicle_response.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
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
          return AppScaffold(
            backgroundColor: AppColors.kWhiteColor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.kMainColor),
            ),
          );
        }

        return AppScaffold(
          backgroundColor: AppColors.kWhiteColor,
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
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: MuvamTexts.titleLarge22(
                            context,
                            text: 'My account',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
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
                                color: AppColors.kGreyColor.withOpacity(0.5),
                              ),
                              child: profileProvider.userProfilePhoto.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileProvider.userProfilePhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: AppColors.kGreyColor
                                                    .withOpacity(0.5),
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
                                  color: AppColors.kMainColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.kWhiteColor,
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
                                      : AppColors.kGreyColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () {
                            context.pushNamed(AppRoutes.ratings.name);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MuvamTexts.bodyMedium14(
                                context,
                                text: 'View ratings',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kBlackColor,
                              ),
                              SizedBox(width: 5.w),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: AppColors.kBlackColor,
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
                                  MuvamTexts.titleMedium18(
                                    context,
                                    text: 'My Car',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kBlackColor,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await context.pushNamed(
                                        AppRoutes.carInformation.name,
                                      );
                                      _loadPrimaryVehicle();
                                    },
                                    child: MuvamTexts.bodyMedium14(
                                      context,
                                      text: '+ Add another vehicle',
                                      isTextWidget: true,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.kMainColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15.h),
                              GestureDetector(
                                onTap: () async {
                                  await context.pushNamed('myCars');
                                  _loadPrimaryVehicle();
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.kFormFieldColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 10.h,
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
                                                      color:
                                                          AppColors.kMainColor,
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
                                                  MuvamTexts.bodySmall12(
                                                    context,
                                                    text: 'Active car',
                                                    isTextWidget: true,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.kGreyColor,
                                                  ),
                                                  if (primaryVehicle != null)
                                                    MuvamTexts.bodyMedium14(
                                                      context,
                                                      text: primaryVehicle!
                                                          .displayName,
                                                      isTextWidget: true,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.kBlackColor,
                                                      maxLines: 1,
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
                                        color: AppColors.kBlackColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(AppRoutes.appLock.name);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.sp),
                                  decoration: BoxDecoration(
                                    color: AppColors.kWhiteColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: AppColors.kGreyColor.withOpacity(
                                        0.3,
                                      ),
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
                                          color: AppColors.kMainColor
                                              .withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          color: AppColors.kMainColor,
                                          size: 28.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MuvamTexts.bodyMedium14(
                                              context,
                                              text: 'Set up biometrics',
                                              isTextWidget: true,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.kBlackColor,
                                            ),
                                            SizedBox(height: 2.h),
                                            MuvamTexts.bodySmall12(
                                              context,
                                              text:
                                                  'Secure your app with fingerprint \nor face unlock',
                                              isTextWidget: true,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    AppRoutes.deleteAccount.name,
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        ConstImages.bin,
                                        width: 20.w,
                                        height: 20.h,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 16.w),
                                      MuvamTexts.bodyMedium14(
                                        context,
                                        text: 'Delete account',
                                        isTextWidget: true,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kFailureColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DeviceBottomPadding(),
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
