import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/colors.dart';
import '../constants/fonts.dart';
import '../constants/theme_manager.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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
    if (driverLicense == null || vehicleRegistration == null || insurance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload all required documents')),
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Upload failed')),
      );
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
          icon: Icon(Icons.arrow_back, color: themeManager.getTextColor(context)),
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
            _buildKycTile(
              imagePath: 'assets/images/kyc.png',
              title: "Driver's License",
              subtitle: "Upload your driver's license (JPG or PNG)",
              isUploaded: driverLicense != null,
              onTap: () => _pickImage('driver_license'),
            ),
            SizedBox(height: 20.h),
            _buildKycTile(
              imagePath: 'assets/images/Account.png',
              title: "Vehicle Registration",
              subtitle: "Upload your vehicle registration document (JPG or PNG)",
              isUploaded: vehicleRegistration != null,
              onTap: () => _pickImage('vehicle_registration'),
            ),
            SizedBox(height: 20.h),
            _buildKycTile(
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

  Widget _buildKycTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isUploaded = false,
  }) {
    return Builder(
      builder: (context) {
        final themeManager = Provider.of<ThemeManager>(context);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  imagePath,
                  width: 16.w,
                  height: 16.h,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: ConstFonts.inter,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          height: 1.0,
                          color: themeManager.getTextColor(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: ConstFonts.inter,
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                          height: 1.0,
                          color: themeManager.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  isUploaded ? Icons.check_circle : Icons.upload,
                  size: 20.sp,
                  color: isUploaded ? Colors.green : Color(ConstColors.mainColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}