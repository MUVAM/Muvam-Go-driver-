import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/vehicles/data/models/vehicle_response.dart';
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
    // final token = await TokenManager.getToken();
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
    // final token = await TokenManager.getToken();
    if (token == null) return;

    final response = await ApiService.setPrimaryVehicle(id, token);
    if (response['success']) {
      // Show success message
      Flushbar(
        title: "Success",
        message: "Successfully set this vehicle as your default",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);

      // Reload vehicles to reflect the updated default status
      await _loadVehicles();
    } else {
      // Show error message
      Flushbar(
        title: "Error",
        message:
            response['message'] ??
            "Failed to set default vehicle. Please try again.",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      width: 33.w,
                      height: 33.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'My cars',
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
            SizedBox(height: 30.h),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(ConstColors.mainColor),
                  ),
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
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              title: Text(
                                'Set Default Vehicle',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              content: Text(
                                'Do you want to set "${vehicle.displayName}" as your default vehicle?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(ConstColors.mainColor),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        // If user confirmed, set as primary vehicle
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
                                            child: Icon(Icons.directions_car),
                                          ),
                                    )
                                  : Container(
                                      width: 60.w,
                                      height: 60.h,
                                      color: Colors.grey.shade300,
                                      child: Icon(Icons.directions_car),
                                    ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.displayName,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${vehicle.year} • ${vehicle.color}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Color(ConstColors.mainColor),
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
