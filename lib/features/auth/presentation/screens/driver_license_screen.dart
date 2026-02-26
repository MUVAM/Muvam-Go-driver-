import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';

class DriverLicenseScreen extends StatefulWidget {
  final String token;
  final String carMake;
  final String carModel;
  final String carYear;
  final String carSeats;
  final String licensePlate;
  final String licenseNumber;
  final String carColor;
  final bool isAcEnabled;

  const DriverLicenseScreen({
    super.key,
    required this.token,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carSeats,
    required this.licensePlate,
    required this.licenseNumber,
    required this.carColor,
    required this.isAcEnabled,
  });

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  final TextEditingController driverLicenseNumberController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? driverLicenseFile;
  bool isLoading = false;

  @override
  void dispose() {
    driverLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDriverLicense() async {
    //📸 User tapped to pick driver license image');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          driverLicenseFile = File(pickedFile.path);
        });
        //✅ Driver license image selected: ${pickedFile.path}');
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Driver license image selected',
        );
      } else {
        //❌ No image selected');
      }
    } catch (e) {
      //❌ Error picking driver license image: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to pick image: $e',
      );
    }
  }

  Future<void> _submitDriverLicense() async {
    AppLogger.log(
      '\n🚀 ========== STARTING DRIVER LICENSE VERIFICATION ==========',
    );
    //📋 Step 1: Validating driver license fields...');

    if (driverLicenseNumberController.text.isEmpty) {
      //❌ Validation failed: Driver license number is empty');
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter your driver license number',
      );
      return;
    }

    if (driverLicenseFile == null) {
      //❌ Validation failed: Driver license file not uploaded');
      CustomFlushbar.showError(
        context: context,
        message: 'Please upload your driver license photo',
      );
      return;
    }

    //✅ All fields validated successfully');
    AppLogger.log(
      '📝 Driver License Number: ${driverLicenseNumberController.text}',
    );
    //📝 Driver License File: ${driverLicenseFile!.path}');

    setState(() => isLoading = true);

    try {
      AppLogger.log(
        '\n📋 Step 2: Calling uploadVerificationDocuments endpoint...',
      );
      //🌐 Endpoint: /users/verification');
      //📤 Uploading driver license for verification...');

      final verificationResult = await ApiService.uploadVerificationDocuments(
        driverLicenseFile: driverLicenseFile!,
        driverLicenseNumber: driverLicenseNumberController.text,
        token: widget.token,
      );

      //\n📥 Verification API Response received');
      //Response: $verificationResult');

      if (!mounted) {
        //⚠️ Widget unmounted, stopping flow');
        return;
      }

      if (verificationResult['success'] == true) {
        // //✅ Driver license verification SUCCESSFUL!');
        // //\n📋 Step 3: Returning to Upload Documents Screen...');
        // //🎯 Returning with driver license file');

        // Return to upload documents screen with the driver license file
        Navigator.pop(context, driverLicenseFile);

        //✅ Returned to Upload Documents Screen successfully');
        AppLogger.log(
          '========== DRIVER LICENSE VERIFICATION COMPLETE ==========\n',
        );
      } else {
        //❌ Driver license verification FAILED');
        String errorMessage =
            verificationResult['message'] ??
            'Driver license verification failed';
        //Error message: $errorMessage');

        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      //❌ CRITICAL ERROR in driver license verification flow');
      //Error: $e');
      //Stack trace: $stackTrace');

      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        //🔄 Loading state reset');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: themeManager.getTextColor(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      Text(
                        'Driver License',
                        style: TextStyle(
                          fontFamily: ConstFonts.inter,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                          color: themeManager.getTextColor(context),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Please provide your driver license details',
                    style: TextStyle(
                      fontFamily: ConstFonts.inter,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      color: themeManager.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver License Number TextField
                      Text(
                        'Driver License Number',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: themeManager.getTextColor(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: driverLicenseNumberController,
                        decoration: InputDecoration(
                          hintText: 'Enter your driver license number',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14.sp,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: Color(ConstColors.mainColor),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Driver License Photo
                      Text(
                        'Driver License Photo',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: themeManager.getTextColor(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: _pickDriverLicense,
                        child: Container(
                          width: double.infinity,
                          height: 200.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: driverLicenseFile != null
                                  ? Color(ConstColors.mainColor)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            color: driverLicenseFile != null
                                ? Color(ConstColors.mainColor).withOpacity(0.05)
                                : Colors.grey.shade50,
                          ),
                          child: driverLicenseFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.file(
                                        driverLicenseFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 50.sp,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'Tap to upload driver license',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isLoading ? null : _submitDriverLicense,
                    child: Container(
                      width: double.infinity,
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
          ],
        ),
      ),
    );
  }
}
