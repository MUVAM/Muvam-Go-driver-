import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/kyc_document_tile.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muvam_rider/core/services/api_service.dart';
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
    final result = await context.pushNamed(
      AppRoutes.driverLicense.name,
      extra: {
        'token': widget.token,
        'carMake': widget.carMake,
        'carModel': widget.carModel,
        'carYear': widget.carYear,
        'carSeats': widget.carSeats,
        'licenseNumber': widget.licenseNumber,
        'licensePlate': widget.licensePlate,
        'carColor': widget.carColor,
        'isAcEnabled': widget.isAcEnabled,
      },
    );

    if (result != null && result is File) {
      setState(() {
        driverLicense = result;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _navigateToInsuranceScreen();
      }
    }
  }

  Future<void> _navigateToInsuranceScreen() async {
    if (driverLicense == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload driver license first',
      );
      return;
    }

    final result = await context.pushNamed(AppRoutes.vehicleInsurance.name);

    if (result != null && result is File) {
      setState(() {
        insurance = result;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _navigateToRegistrationScreen();
      }
    }
  }

  Future<void> _navigateToRegistrationScreen() async {
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

    final result = await context.pushNamed(AppRoutes.vehicleRegistration.name);

    if (result != null && result is File) {
      setState(() {
        vehicleRegistration = result;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _navigateToVehiclePhotosScreen();
      }
    }
  }

  Future<void> _navigateToVehiclePhotosScreen() async {
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

    final result = await context.pushNamed(AppRoutes.vehiclePhotos.name);

    if (result != null && result is List<File>) {
      setState(() {
        vehiclePhotos = result;
      });
    }
  }

  Future<File> _compressIfNeeded(File file) async {
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    if (sizeInMB <= 2) {
      AppLogger.log(
        'File is ${sizeInMB.toStringAsFixed(2)} MB — no compression needed',
      );
      return file;
    }

    AppLogger.log(
      'File is ${sizeInMB.toStringAsFixed(2)} MB — compressing to JPEG 70%...',
    );

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (compressedFile == null) {
      return file;
    }

    final compressedSizeMB =
        await File(compressedFile.path).length() / (1024 * 1024);
    AppLogger.log('Compressed to ${compressedSizeMB.toStringAsFixed(2)} MB');
    return File(compressedFile.path);
  }

  Future<void> _uploadDocuments() async {
    AppLogger.log('========== UPLOAD DOCUMENTS BUTTON TAPPED ==========');

    if (driverLicense == null ||
        vehicleRegistration == null ||
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
      final compressedLicense = await _compressIfNeeded(driverLicense!);
      final compressedInsurance = await _compressIfNeeded(insurance!);
      final compressedRegistration = await _compressIfNeeded(
        vehicleRegistration!,
      );
      final compressedPhotos = await Future.wait(
        vehiclePhotos.map((photo) => _compressIfNeeded(photo)),
      );

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

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('vehicle_submitted', true);

        context.pushReplacementNamed(
          AppRoutes.documentVerificationSuccess.name,
        );

        AppLogger.log(
          '========== VEHICLE REGISTRATION FLOW COMPLETE ==========',
        );
      } else {
        String errorMessage = result['message'] ?? 'Registration failed';
        if (errorMessage.contains('413') ||
            errorMessage.contains('Too Large')) {
          errorMessage = 'Images are too large. Please select smaller images.';
        }
        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                          color: AppColors.kBlackColor,
                        ),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      MuvamTexts.headlineSmall24(
                        context,
                        text: 'Upload Documents',
                        isTextWidget: true,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kBlackColor,
                      ),
                      const Spacer(),
                    ],
                  ),
                  MuvamTexts.bodyMedium14(
                    context,
                    text:
                        'Please Submit the following documents to \nverify your vehicle',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                    center: true,
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
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.kWhiteColor,
                        ),
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
                          color: _isLoading
                              ? AppColors.kMainColor
                              : (driverLicense != null &&
                                    insurance != null &&
                                    vehicleRegistration != null &&
                                    vehiclePhotos.length >= 3)
                              ? AppColors.kMainColor
                              : AppColors.kGreyColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: MuvamTexts.button16(
                            context,
                            text: 'Upload Documents',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kWhiteColor,
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
