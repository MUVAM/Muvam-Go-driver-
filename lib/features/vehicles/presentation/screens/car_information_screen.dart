import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/car_text_field.dart';

class CarInformationScreen extends StatefulWidget {
  const CarInformationScreen({super.key});

  @override
  State<CarInformationScreen> createState() => _CarInformationScreenState();
}

class _CarInformationScreenState extends State<CarInformationScreen> {
  final TextEditingController makeController = TextEditingController();
  final TextEditingController modelTypeController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  File? vehiclePhoto;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: themeManager.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeManager.getTextColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Text(
                  'Car Information',
                  style: ConstTextStyles.createAccountTitle.copyWith(
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your car details correctly.',
                  style: ConstTextStyles.createAccountSubtitle.copyWith(
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 30.h),
                CarTextField(
                  label: 'Make',
                  controller: makeController,
                ),
                SizedBox(height: 20.h),
                CarTextField(
                  label: 'Model Type',
                  controller: modelTypeController,
                ),
                SizedBox(height: 20.h),
                CarTextField(
                  label: 'Number of Seats',
                  controller: seatsController,
                ),
                SizedBox(height: 20.h),
                CarTextField(
                  label: 'Year',
                  controller: yearController,
                ),
                SizedBox(height: 20.h),
                CarTextField(
                  label: 'License Number',
                  controller: licenseNumberController,
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _pickVehiclePhoto,
                  child: Container(
                    width: 353.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: vehiclePhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              vehiclePhoto!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Upload Vehicle Photo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: isLoading ? null : _registerVehicle,
                  child: Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: isLoading
                          ? Colors.grey
                          : Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Continue',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickVehiclePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        vehiclePhoto = File(image.path);
      });
    }
  }

  Future<void> _registerVehicle() async {
    if (makeController.text.isEmpty ||
        modelTypeController.text.isEmpty ||
        seatsController.text.isEmpty ||
        yearController.text.isEmpty ||
        licenseNumberController.text.isEmpty ||
        vehiclePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload vehicle photo')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final result = await ApiService.registerVehicle(
          make: makeController.text,
          modelType: modelTypeController.text,
          seats: seatsController.text,
          year: yearController.text,
          licenseNumber: licenseNumberController.text,
          vehiclePhotoFile: vehiclePhoto!,
          token: token,
        );

        if (result['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Registration failed')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
