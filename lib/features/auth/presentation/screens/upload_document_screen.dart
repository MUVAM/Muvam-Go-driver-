import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/kyc_document_tile.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

import 'package:muvam_rider/features/auth/presentation/screens/vehicle_insurance_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/vehicle_registration_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/vehicle_photos_screen.dart';

import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/screens/document_verification_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycVerificationScreen extends StatefulWidget {
  final String token;
  final String carMake;
  final String carModel;
  final String carYear;
  final String carSeats;
  final String licensePlate;
  final String licenseNumber;
  final String carColor;
  final bool isAcEnabled;

  const KycVerificationScreen({
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
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  File? insurance;
  File? vehicleRegistration;
  List<File> vehiclePhotos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUploadStatus();
    });
  }

  void _checkUploadStatus() {
    setState(() {});
  }

  Future<void> _navigateToInsuranceScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehicleInsuranceScreen()),
    );
    if (result != null && result is File) {
      setState(() {
        insurance = result;
      });
      // Add delay to ensure camera is properly disposed before navigating
      await Future.delayed(const Duration(milliseconds: 500));
      // Automatically navigate to registration screen after insurance upload
      if (mounted) {
        _navigateToRegistrationScreen();
      }
    }
  }

  Future<void> _navigateToRegistrationScreen() async {
    // Check if insurance is uploaded first
    if (insurance == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload vehicle insurance first',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehicleRegistrationScreen(),
      ),
    );
    if (result != null && result is File) {
      setState(() {
        vehicleRegistration = result;
      });
      // Add delay to ensure camera is properly disposed before navigating
      await Future.delayed(const Duration(milliseconds: 500));
      // Automatically navigate to vehicle photos screen after registration upload
      if (mounted) {
        _navigateToVehiclePhotosScreen();
      }
    }
  }

  Future<void> _navigateToVehiclePhotosScreen() async {
    // Check if previous documents are uploaded first
    if (insurance == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload vehicle insurance first',
      );
      return;
    }
    if (vehicleRegistration == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload vehicle registration first',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehiclePhotosScreen()),
    );
    if (result != null && result is List<File>) {
      setState(() {
        vehiclePhotos = result;
      });
      // Return to upload documents screen - user will manually tap upload button
    }
  }

  Future<void> _uploadDocuments() async {
    AppLogger.log('\n🚀 ========== UPLOAD DOCUMENTS BUTTON TAPPED ==========');
    AppLogger.log(
      '📋 Current Screen: Upload Documents Screen (KycVerificationScreen)',
    );
    AppLogger.log('📋 Step 1: Validating uploaded documents...');

    if (vehicleRegistration == null ||
        insurance == null ||
        vehiclePhotos.length < 3) {
      AppLogger.log('❌ Validation failed: Missing required documents');
      AppLogger.log(
        'Vehicle Registration: ${vehicleRegistration != null ? "✅" : "❌"}',
      );
      AppLogger.log('Insurance: ${insurance != null ? "✅" : "❌"}');
      AppLogger.log('Vehicle Photos: ${vehiclePhotos.length}/3');

      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload all required documents',
      );
      return;
    }

    AppLogger.log('✅ All documents validated successfully');
    AppLogger.log('📝 Vehicle Registration: ${vehicleRegistration!.path}');
    AppLogger.log('📝 Insurance: ${insurance!.path}');
    AppLogger.log('📝 Vehicle Photos: ${vehiclePhotos.length} photos');

    setState(() => _isLoading = true);

    try {
      AppLogger.log('\n📋 Step 2: Calling registerVehicle endpoint...');
      AppLogger.log('🌐 Endpoint: /rides/vehicle');
      AppLogger.log('📤 Uploading vehicle information and documents...');
      AppLogger.log('📦 Car Make: ${widget.carMake}');
      AppLogger.log('📦 Car Model: ${widget.carModel}');
      AppLogger.log('📦 Car Year: ${widget.carYear}');
      AppLogger.log('📦 Seats: ${widget.carSeats}');
      AppLogger.log('📦 License Plate: ${widget.licensePlate}');
      AppLogger.log('📦 Color: ${widget.carColor}');
      AppLogger.log('📦 AC Enabled: ${widget.isAcEnabled}');

      final result = await ApiService.registerVehicle(
        make: widget.carMake,
        modelType: widget.carModel,
        seats: widget.carSeats,
        year: widget.carYear,
        licenseNumber: widget.licenseNumber,
        color: widget.carColor,
        licensePlate: widget.licensePlate,
        registrationDoc: vehicleRegistration!,
        insuranceDoc: insurance!,
        vehiclePhotos: vehiclePhotos,
        token: widget.token,
        ac: widget.isAcEnabled,
      );

      AppLogger.log('\n📥 Vehicle Registration API Response received');
      AppLogger.log('Response: $result');

      if (!mounted) {
        AppLogger.log('⚠️ Widget unmounted, stopping flow');
        return;
      }

      if (result['success'] == true) {
        AppLogger.log('✅ Vehicle registration SUCCESSFUL!');

        // Update vehicle_submitted status in SharedPreferences
        AppLogger.log(
          '💾 Saving vehicle_submitted status to SharedPreferences...',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('vehicle_submitted', true);
        AppLogger.log('✅ vehicle_submitted status saved: true');

        AppLogger.log('\n📋 Step 3: Navigating to Success Screen...');
        AppLogger.log('🎯 Next screen: DocumentVerificationSuccessScreen');

        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentVerificationSuccessScreen(),
          ),
        );

        AppLogger.log('✅ Navigation to Success Screen successful');
        AppLogger.log(
          '========== VEHICLE REGISTRATION FLOW COMPLETE ==========\n',
        );
      } else {
        AppLogger.log('❌ Vehicle registration FAILED');
        String errorMessage = result['message'] ?? 'Registration failed';
        if (errorMessage.contains('413') ||
            errorMessage.contains('Too Large')) {
          errorMessage = 'Images are too large. Please select smaller images.';
        }
        AppLogger.log('Error message: $errorMessage');

        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ CRITICAL ERROR in upload documents flow');
      AppLogger.log('Error: $e');
      AppLogger.log('Stack trace: $stackTrace');

      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        AppLogger.log('🔄 Loading state reset');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('check user access token:${widget.token}');
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
                        'Upload Documents',
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
                  Text(
                    'Please Submit the following documents to \nverify your vehicle',
                    style: TextStyle(
                      fontFamily: ConstFonts.inter,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      color: themeManager.getTextColor(context),
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
                    children: [
                      KycDocumentTile(
                        icon: ConstImages.streamlineSolar,
                        title: 'Vehicle Insurance',
                        subtitle:
                            'Upload a valid copy of your vehicle insurance to confirm your car is properly insured for ride-hailing services.',
                        isUploaded: insurance != null,
                        onTap: _navigateToInsuranceScreen,
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
                      KycDocumentTile(
                        icon: ConstImages.basilDocument,
                        title: 'Vehicle Registration',
                        subtitle:
                            'Provide an up-to-date vehicle registration documents to verify ownership and eligibility to operate on the platform',
                        isUploaded: vehicleRegistration != null,
                        onTap: _navigateToRegistrationScreen,
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
                      KycDocumentTile(
                        icon: ConstImages.tablerCamera,
                        title: 'Vehicle images',
                        subtitle:
                            'Provide an up-to-date vehicle registration documents to verify ownership and eligibility to operate on the platform',
                        isUploaded: vehiclePhotos.length >= 3,
                        onTap: _navigateToVehiclePhotosScreen,
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: const Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 48.h,
                      decoration: BoxDecoration(
                        // color: const Color(ConstColors.mainColor),
                        color: _isLoading
                            ? const Color(ConstColors.mainColor)
                            : (insurance != null &&
                                  vehicleRegistration != null &&
                                  vehiclePhotos.length >= 3)
                            ? const Color(ConstColors.mainColor)
                            : Color(0xffB1B1B1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _uploadDocuments,
                        child: Center(
                          child: Text(
                            'Upload Documents',
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
