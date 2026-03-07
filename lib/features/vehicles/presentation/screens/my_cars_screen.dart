import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/vehicles/data/models/vehicle_response.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  List<VehicleDetail> vehicles = [];
  bool isLoading = true;
  VehicleDetail? selectedVehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final response = await ApiService.getVehicles(token);
    if (response['success']) {
      final vehicleResponse = VehicleResponse.fromJson(response['data']);
      setState(() {
        vehicles = vehicleResponse.vehicles;
        selectedVehicle = vehicles.firstWhere(
          (v) => v.isDefault,
          orElse: () =>
              vehicles.isNotEmpty ? vehicles.first : null as VehicleDetail,
        );
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _setPrimaryVehicle(dynamic id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final response = await ApiService.setPrimaryVehicle(id, token);
    if (response['success']) {
      CustomFlushbar.showSuccess(
        context: context,
        message: "Successfully set this vehicle as your default",
      );
      await _loadVehicles();
    } else {
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to set default vehicle. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'My cars',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kMainColor),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: vehicles.length,
                  separatorBuilder: (context, index) =>
                      Divider(thickness: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final isSelected = selectedVehicle?.id == vehicle.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedVehicle = vehicle);
                      },
                      onLongPress: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              title: MuvamTexts.titleMedium18(
                                context,
                                text: 'Set Default Vehicle',
                                isTextWidget: true,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kBlackColor,
                              ),
                              content: MuvamTexts.bodyMedium14(
                                context,
                                text:
                                    'Do you want to set "${vehicle.displayName}" as your default vehicle?',
                                isTextWidget: true,
                                fontWeight: FontWeight.w400,
                                color: AppColors.kBlackColor,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: MuvamTexts.bodyMedium14(
                                    context,
                                    text: 'Cancel',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.kGreyColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.pop(true),
                                  child: MuvamTexts.bodyMedium14(
                                    context,
                                    text: 'Confirm',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kMainColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          _setPrimaryVehicle(vehicle.id);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: vehicle.primaryPhoto != null
                                  ? Image.network(
                                      vehicle.primaryPhoto!.url,
                                      width: 60.w,
                                      height: 60.h,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          Container(
                                            width: 60.w,
                                            height: 60.h,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.directions_car,
                                            ),
                                          ),
                                    )
                                  : Container(
                                      width: 60.w,
                                      height: 60.h,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.directions_car),
                                    ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MuvamTexts.bodyLarge16(
                                    context,
                                    text: vehicle.displayName,
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kBlackColor,
                                  ),
                                  SizedBox(height: 4.h),
                                  MuvamTexts.bodyMedium14(
                                    context,
                                    text: '${vehicle.year} • ${vehicle.color}',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.kGreyColor,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.kMainColor,
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
