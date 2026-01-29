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
    // Listen for results when returning from upload screens
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
      MaterialPageRoute(
        builder: (context) => const VehicleInsuranceScreen(),
      ),
    );
    if (result != null && result is File) {
      setState(() {
        insurance = result;
      });
    }
  }

  Future<void> _navigateToRegistrationScreen() async {
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
    }
  }

  Future<void> _navigateToVehiclePhotosScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehiclePhotosScreen(),
      ),
    );
    if (result != null && result is List<File>) {
      setState(() {
        vehiclePhotos = result;
      });
    }
  }

  Future<void> _uploadDocuments() async {
    if (vehicleRegistration == null ||
        insurance == null ||
        vehiclePhotos.length < 3) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload all required documents',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentVerificationSuccessScreen(),
          ),
        );
      } else {
        String errorMessage = result['message'] ?? 'Registration failed';
        if (errorMessage.contains('413') || errorMessage.contains('Too Large')) {
          errorMessage = 'Images are too large. Please select smaller images.';
        }
        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e) {
      CustomFlushbar.showError(context: context, message: 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                    child: GestureDetector(
                      onTap: _isLoading ? null : _uploadDocuments,
                      child: Center(
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
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
