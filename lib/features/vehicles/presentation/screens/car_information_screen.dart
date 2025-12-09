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
  final TextEditingController colorController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  File? vehiclePhoto;
  File? registrationDoc;
  File? insuranceDoc;
  List<File> vehiclePhotos = [];
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
                CarTextField(
                  label: 'Color',
                  controller: colorController,
                ),
                SizedBox(height: 20.h),
                CarTextField(
                  label: 'License Plate',
                  controller: licensePlateController,
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _pickRegistrationDoc,
                  child: Container(
                    width: 353.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: registrationDoc != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(registrationDoc!, fit: BoxFit.cover, width: double.infinity),
                              ),
                              Positioned(
                                top: 4.h,
                                right: 4.w,
                                child: GestureDetector(
                                  onTap: () => setState(() => registrationDoc = null),
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 40.sp, color: Colors.grey),
                              SizedBox(height: 8.h),
                              Text('Upload Registration Doc', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _pickInsuranceDoc,
                  child: Container(
                    width: 353.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: insuranceDoc != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(insuranceDoc!, fit: BoxFit.cover, width: double.infinity),
                              ),
                              Positioned(
                                top: 4.h,
                                right: 4.w,
                                child: GestureDetector(
                                  onTap: () => setState(() => insuranceDoc = null),
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 40.sp, color: Colors.grey),
                              SizedBox(height: 8.h),
                              Text('Upload Insurance Doc', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _pickVehiclePhotos,
                  child: Container(
                    width: 353.w,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: vehiclePhotos.isNotEmpty
                        ? Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: vehiclePhotos.asMap().entries.map((entry) {
                              int index = entry.key;
                              File photo = entry.value;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: Image.file(photo, width: 80.w, height: 80.h, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 2.h,
                                    right: 2.w,
                                    child: GestureDetector(
                                      onTap: () => setState(() => vehiclePhotos.removeAt(index)),
                                      child: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Icon(Icons.close, color: Colors.white, size: 12.sp),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        : Container(
                            height: 120.h,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40.sp, color: Colors.grey),
                                SizedBox(height: 8.h),
                                Text('Upload Vehicle Photos', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                              ],
                            ),
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

  Future<void> _pickRegistrationDoc() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 40,
    );
    if (image != null) {
      setState(() {
        registrationDoc = File(image.path);
      });
    }
  }

  Future<void> _pickInsuranceDoc() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 40,
    );
    if (image != null) {
      setState(() {
        insuranceDoc = File(image.path);
      });
    }
  }

  Future<void> _pickVehiclePhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 40, maxWidth: 1280, maxHeight: 1280);
    if (images.isNotEmpty) {
      setState(() {
        vehiclePhotos = images.map((img) => File(img.path)).toList();
      });
    }
  }

  Future<void> _registerVehicle() async {
    print('=== REGISTER VEHICLE DEBUG START ===');
    print('Make: ${makeController.text}');
    print('Model Type: ${modelTypeController.text}');
    print('Seats: ${seatsController.text}');
    print('Year: ${yearController.text}');
    print('License Number: ${licenseNumberController.text}');
    print('Vehicle Photo: ${vehiclePhoto?.path}');
    
    if (makeController.text.isEmpty ||
        modelTypeController.text.isEmpty ||
        seatsController.text.isEmpty ||
        yearController.text.isEmpty ||
        licenseNumberController.text.isEmpty ||
        colorController.text.isEmpty ||
        licensePlateController.text.isEmpty ||
        registrationDoc == null ||
        insuranceDoc == null ||
        vehiclePhotos.length < 3) {
      print('❌ Validation failed - missing fields');
      String message = vehiclePhotos.length < 3 
          ? 'Please upload at least 3 vehicle photos'
          : 'Please fill all fields and upload all documents';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    print('✅ All fields validated successfully');
    setState(() {
      isLoading = true;
    });

    try {
      print('🔍 Getting auth token from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      print('Token found: ${token != null}');
      if (token != null) {
        print('Token preview: ${token.substring(0, 20)}...');
      }

      if (token != null) {
        print('📤 Calling ApiService.registerVehicle...');
        final result = await ApiService.registerVehicle(
          make: makeController.text,
          modelType: modelTypeController.text,
          seats: seatsController.text,
          year: yearController.text,
          licenseNumber: licenseNumberController.text,
          color: colorController.text,
          licensePlate: licensePlateController.text,
          registrationDoc: registrationDoc!,
          insuranceDoc: insuranceDoc!,
          vehiclePhotos: vehiclePhotos,
          token: token,
        );

        print('📥 API Response received:');
        print('Success: ${result['success']}');
        print('Message: ${result['message']}');
        print('Full result: $result');

        if (result['success'] == true) {
          print('✅ Vehicle registration successful - navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          print('❌ Vehicle registration failed: ${result['message']}');
          String errorMessage = result['message'] ?? 'Registration failed';
          
          // Handle authentication errors
          if (errorMessage.contains('user not found') || errorMessage.contains('unauthorized')) {
            errorMessage = 'Your session has expired. Please login again.';
            // Clear the invalid token
            await prefs.remove('auth_token');
            // Navigate back to login screen
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            return;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        print('❌ No auth token found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found. Please login again.')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION in _registerVehicle: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      print('🔄 Setting isLoading to false');
      setState(() {
        isLoading = false;
      });
      print('=== REGISTER VEHICLE DEBUG END ===\n');
    }
  }
}
