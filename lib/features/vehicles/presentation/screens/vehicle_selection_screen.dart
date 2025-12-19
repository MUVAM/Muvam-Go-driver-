import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
// import 'package:muvam_rider/core/utils/token_manager.dart';
import 'package:muvam_rider/features/vehicles/data/models/vehicle_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
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
          orElse: () => vehicles.isNotEmpty ? vehicles.first : null as VehicleDetail,
        );
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
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
                      width: 24.w,
                      height: 24.h,
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
                  separatorBuilder: (context, index) => Divider(
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final isSelected = selectedVehicle?.id == vehicle.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedVehicle = vehicle);
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
