import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
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
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          driverLicenseFile = File(pickedFile.path);
        });
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Driver license image selected',
        );
      }
    } catch (e) {
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to pick image: $e',
      );
    }
  }

  Future<void> _submitDriverLicense() async {
    if (driverLicenseNumberController.text.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter your driver license number',
      );
      return;
    }

    if (driverLicenseFile == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please upload your driver license photo',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final verificationResult = await ApiService.uploadVerificationDocuments(
        driverLicenseFile: driverLicenseFile!,
        driverLicenseNumber: driverLicenseNumberController.text,
        token: widget.token,
      );

      if (!mounted) return;

      if (verificationResult['success'] == true) {
        Navigator.pop(context, driverLicenseFile);
      } else {
        String errorMessage =
            verificationResult['message'] ??
            'Driver license verification failed';

        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AppScaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
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
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      MuvamTexts.titleLarge22(
                        context,
                        text: 'Driver License',
                        isTextWidget: true,
                        fontWeight: FontWeight.w700,
                        color: themeManager.getTextColor(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'Please provide your driver license details',
                    isTextWidget: true,
                    center: true,
                    color: themeManager.getSecondaryTextColor(context),
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
                      MuvamTexts.bodyMedium14(
                        context,
                        text: 'Driver License Number',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: themeManager.getTextColor(context),
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
                            borderSide: const BorderSide(
                              color: AppColors.kMainColor,
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
                      MuvamTexts.bodyMedium14(
                        context,
                        text: 'Driver License Photo',
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                        color: themeManager.getTextColor(context),
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
                                  ? AppColors.kMainColor
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            color: driverLicenseFile != null
                                ? AppColors.kMainColor.withOpacity(0.05)
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
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: AppColors.kWhiteColor,
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
                                    MuvamTexts.bodyMedium14(
                                      context,
                                      text: 'Tap to upload driver license',
                                      isTextWidget: true,
                                      color: Colors.grey.shade600,
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
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: isLoading
                            ? AppColors.kGreyColor
                            : AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.kWhiteColor,
                              )
                            : MuvamTexts.button16(
                                context,
                                text: 'Continue',
                                color: AppColors.kWhiteColor,
                                fontWeight: FontWeight.w600,
                                isTextWidget: true,
                              ),
                      ),
                    ),
                  ),
                  DeviceBottomPadding(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
