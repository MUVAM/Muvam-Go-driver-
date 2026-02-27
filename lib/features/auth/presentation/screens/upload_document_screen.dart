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
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'package:muvam_rider/features/auth/presentation/screens/driver_license_screen.dart';
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
  File? driverLicense;
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

  Future<void> _navigateToDriverLicenseScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverLicenseScreen(
          token: widget.token,
          carMake: widget.carMake,
          carModel: widget.carModel,
          carYear: widget.carYear,
          carSeats: widget.carSeats,
          licenseNumber: widget.licenseNumber,
          licensePlate: widget.licensePlate,
          carColor: widget.carColor,
          isAcEnabled: widget.isAcEnabled,
        ),
      ),
    );
    if (result != null && result is File) {
      setState(() {
        driverLicense = result;
      });
      // Add delay to ensure proper state update
      await Future.delayed(const Duration(milliseconds: 500));
      // Automatically navigate to insurance screen after driver license upload
      if (mounted) {
        _navigateToInsuranceScreen();
      }
    }
  }

  Future<void> _navigateToInsuranceScreen() async {
    // Check if driver license is uploaded first
    if (driverLicense == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload driver license first',
      );
      return;
    }

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
    // Check if previous documents are uploaded first
    if (driverLicense == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload driver license first',
      );
      return;
    }
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
    if (driverLicense == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload driver license first',
      );
      return;
    }
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
Future<File> _compressIfNeeded(
    File file, {
    bool alwaysCompress = false,
    double maxSizeMB = 1.0,
    int quality = 60,
  }) async {
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    AppLogger.log(
      '📁 File: ${file.path.split('/').last} | Size: ${sizeInMB.toStringAsFixed(2)} MB',
    );

    if (!alwaysCompress && sizeInMB <= maxSizeMB) {
      AppLogger.log('✅ Within limit — no compression needed');
      return file;
    }

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    AppLogger.log('🗜️ Compressing at quality=$quality...');
    XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (compressedFile == null) {
      AppLogger.log('⚠️ Compression returned null — using original');
      return file;
    }

    double compressedSizeMB =
        await File(compressedFile.path).length() / (1024 * 1024);
    AppLogger.log(
      '📦 After quality=$quality: ${compressedSizeMB.toStringAsFixed(2)} MB',
    );

    // Still too large — compress again more aggressively
    if (compressedSizeMB > maxSizeMB) {
      AppLogger.log('🗜️ Still too large, re-compressing at quality=30...');
      final targetPath2 =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_v2.jpg';
      final compressedFile2 = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath2,
        quality: 30,
        format: CompressFormat.jpeg,
      );
      if (compressedFile2 != null) {
        compressedSizeMB =
            await File(compressedFile2.path).length() / (1024 * 1024);
        AppLogger.log(
          '📦 After quality=30: ${compressedSizeMB.toStringAsFixed(2)} MB',
        );
        compressedFile = compressedFile2;
      }
    }

    AppLogger.log('✅ Final: ${compressedSizeMB.toStringAsFixed(2)} MB');
    return File(compressedFile.path);
  }
  Future<void> _uploadDocuments() async {
    //\n🚀 ========== UPLOAD DOCUMENTS BUTTON TAPPED ==========');
    AppLogger.log(
      '📋 Current Screen: Upload Documents Screen (KycVerificationScreen)',
    );
    //📋 Step 1: Validating uploaded documents...');

    if (driverLicense == null ||
        vehicleRegistration == null ||
        insurance == null ||
        vehiclePhotos.length < 3) {
      //❌ Validation failed: Missing required documents');
      //Driver License: ${driverLicense != null ? "✅" : "❌"}');
      AppLogger.log(
        'Vehicle Registration: ${vehicleRegistration != null ? "✅" : "❌"}',
      );
      //Insurance: ${insurance != null ? "✅" : "❌"}');
      //Vehicle Photos: ${vehiclePhotos.length}/3');

      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload all required documents',
      );
      return;
    }

    //✅ All documents validated successfully');
    //📝 Vehicle Registration: ${vehicleRegistration!.path}');
    //📝 Insurance: ${insurance!.path}');
    //📝 Vehicle Photos: ${vehiclePhotos.length} photos');

    setState(() => _isLoading = true);

    try {
      // ── Step 2a: Compress any files that exceed 2 MB ──────────────────────
      //\n📋 Step 2a: Compressing documents if needed...');

    // Documents — compress if over 1MB
      final compressedLicense = await _compressIfNeeded(
        driverLicense!,
        maxSizeMB: 1.0,
        quality: 60,
      );
      final compressedInsurance = await _compressIfNeeded(
        insurance!,
        maxSizeMB: 1.0,
        quality: 60,
      );
      final compressedRegistration = await _compressIfNeeded(
        vehicleRegistration!,
        maxSizeMB: 1.0,
        quality: 60,
      );

      // Vehicle photos — ALWAYS compress, target 0.8MB each
      final compressedPhotos = await Future.wait(
        vehiclePhotos.map(
          (photo) => _compressIfNeeded(
            photo,
            alwaysCompress: true, // always compress regardless of size
            maxSizeMB: 0.8,
            quality: 55,
          ),
        ),
      );

      //✅ All files compressed/checked successfully');

      // ── Step 2b: Upload ───────────────────────────────────────────────────
      //\n📋 Step 2b: Calling registerVehicle endpoint...');
      //🌐 Endpoint: /rides/vehicle');
      //📤 Uploading vehicle information and documents...');
      //📦 Car Make: ${widget.carMake}');
      //📦 Car Model: ${widget.carModel}');
      //📦 Car Year: ${widget.carYear}');
      //📦 Seats: ${widget.carSeats}');
      //📦 License Plate: ${widget.licensePlate}');
      //📦 Color: ${widget.carColor}');
      //📦 AC Enabled: ${widget.isAcEnabled}');

      final result = await ApiService.registerVehicle(
        make: widget.carMake,
        modelType: widget.carModel,
        seats: widget.carSeats,
        year: widget.carYear,
        licenseNumber: widget.licenseNumber,
        color: widget.carColor,
        licensePlate: widget.licensePlate,
        registrationDoc: compressedRegistration,
        insuranceDoc: compressedInsurance,
        vehiclePhotos: compressedPhotos,
        token: widget.token,
        ac: widget.isAcEnabled,
      );

      //\n📥 Vehicle Registration API Response received');
      //Response: $result');

      if (!mounted) {
        //⚠️ Widget unmounted, stopping flow');
        return;
      }

      if (result['success'] == true) {
        //✅ Vehicle registration SUCCESSFUL!');

        // Update vehicle_submitted status in SharedPreferences
        AppLogger.log(
          '💾 Saving vehicle_submitted status to SharedPreferences...',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('vehicle_submitted', true);
        //✅ vehicle_submitted status saved: true');

        //\n📋 Step 3: Navigating to Success Screen...');
        //🎯 Next screen: DocumentVerificationSuccessScreen');

        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentVerificationSuccessScreen(),
          ),
        );

        //✅ Navigation to Success Screen successful');
        AppLogger.log(
          '========== VEHICLE REGISTRATION FLOW COMPLETE ==========\n',
        );
      } else {
        //❌ Vehicle registration FAILED');
        String errorMessage = result['message'] ?? 'Registration failed';
        if (errorMessage.contains('413') ||
            errorMessage.contains('Too Large')) {
          errorMessage = 'Images are too large. Please select smaller images.';
        }
        //Error message: $errorMessage');

        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      //❌ CRITICAL ERROR in upload documents flow');
      //Error: $e');
      //Stack trace: $stackTrace');

      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        //🔄 Loading state reset');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //check user access token:${widget.token}');
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
                        icon: ConstImages.driversLicense,
                        title: 'Drivers License',
                        subtitle:
                            'Provide an up-to-date vehicle registration documents to verify ownership and eligibility to operate on the platform',
                        isUploaded: driverLicense != null,
                        onTap: _navigateToDriverLicenseScreen,
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
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
                    GestureDetector(
                      onTap: _isLoading ? null : _uploadDocuments,

                      child: Container(
                        width: double.infinity,
                        height: 48.h,
                        decoration: BoxDecoration(
                          // color: const Color(ConstColors.mainColor),
                          color: _isLoading
                              ? const Color(ConstColors.mainColor)
                              : (driverLicense != null &&
                                    insurance != null &&
                                    vehicleRegistration != null &&
                                    vehiclePhotos.length >= 3)
                              ? const Color(ConstColors.mainColor)
                              : Color(0xffB1B1B1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
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
