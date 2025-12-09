import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/vehicles/presentation/screens/car_information_screen.dart';
import '../widgets/kyc_tile.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents uploaded successfully!')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'KYC Verification',
              style: TextStyle(
                fontFamily: ConstFonts.inter,
                fontWeight: FontWeight.w600,
                fontSize: 24.sp,
                color: themeManager.getTextColor(context),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Please Submit the following documents to verify your profile',
              style: TextStyle(
                fontFamily: ConstFonts.inter,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
                color: themeManager.getTextColor(context),
              ),
            ),
            SizedBox(height: 30.h),
            KycTile(
              imagePath: 'assets/images/kyc.png',
              title: "Driver's License",
              subtitle: "Upload your driver's license (JPG or PNG)",
              isUploaded: driverLicense != null,
              onTap: () => _pickImage('driver_license'),
            ),
            SizedBox(height: 20.h),
            KycTile(
              imagePath: 'assets/images/Account.png',
              title: "Vehicle Registration",
              subtitle:
                  "Upload your vehicle registration document (JPG or PNG)",
              isUploaded: vehicleRegistration != null,
              onTap: () => _pickImage('vehicle_registration'),
            ),
            SizedBox(height: 20.h),
            KycTile(
              imagePath: 'assets/images/Account.png',
              title: "Insurance Document",
              subtitle: "Upload your insurance document (JPG or PNG)",
              isUploaded: insurance != null,
              onTap: () => _pickImage('insurance'),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
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
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
