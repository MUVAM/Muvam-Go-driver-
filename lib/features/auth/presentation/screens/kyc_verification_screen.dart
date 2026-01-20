import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/kyc_document_tile.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';

class KycVerificationScreen extends StatefulWidget {
  final String token;

  const KycVerificationScreen({super.key, required this.token});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  File? driverLicense;
  File? vehicleRegistration;
  File? insurance;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        switch (type) {
          case 'driver_license':
            driverLicense = File(image.path);
            break;
          case 'vehicle_registration':
            vehicleRegistration = File(image.path);
            break;
          case 'insurance':
            insurance = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _uploadDocuments() async {
    if (driverLicense == null ||
        vehicleRegistration == null ||
        insurance == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please upload all required documents',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.uploadVerificationDocuments(
      driverLicense: driverLicense!,
      vehicleRegistration: vehicleRegistration!,
      insurance: insurance!,
      token: widget.token,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Documents uploaded successfully!',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CarInformationScreen()),
        (route) => false,
      );
    } else {
      String errorMessage = result['message'] ?? 'Upload failed';
      if (errorMessage.contains('413') || errorMessage.contains('Too Large')) {
        errorMessage =
            'Images are too large. Please select smaller images and try again.';
      }
      CustomFlushbar.showError(context: context, message: errorMessage);
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
                        onTap: () => _pickImage('insurance'),
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
                      KycDocumentTile(
                        icon: ConstImages.basilDocument,
                        title: 'Vehicle Registration',
                        subtitle:
                            'Provide an up-to-date vehicle registration documents to verify ownership and eligibility to operate on the platform',
                        isUploaded: vehicleRegistration != null,
                        onTap: () => _pickImage('vehicle_registration'),
                        themeManager: themeManager,
                      ),
                      Divider(height: 1.h, color: Colors.grey.shade300),
                      KycDocumentTile(
                        icon: ConstImages.tablerCamera,
                        title: 'Vehicle images',
                        subtitle:
                            'Provide an up-to-date vehicle registration documents to verify ownership and eligibility to operate on the platform',
                        isUploaded: driverLicense != null,
                        onTap: () => _pickImage('driver_license'),
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
