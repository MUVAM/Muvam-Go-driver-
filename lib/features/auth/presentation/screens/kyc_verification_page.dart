import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/screens/account_verification_success_screen.dart';
import 'package:qoreidsdk/qoreidsdk.dart';

class KycVerificationPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dob;

  const KycVerificationPage({
    super.key,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dob,
  });

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  bool _isLoading = false;
  bool _driversLicenseVerified = false;
  bool _identityVerified = false;

  @override
  void initState() {
    super.initState();
    _listenToResults();
  }

  void _listenToResults() {
    Qoreidsdk.onResult((result) async {
      debugPrint('QoreID Result: $result');

      // Check for cancellation or error first based on the provided log format
      if (result['code'] == 'E_USER_CANCELED' ||
          result['event'] == 'ERROR_RESULT' ||
          result['message'] == 'User canceled') {
        CustomFlushbar.showError(
          context: context,
          message: result['message'] ?? 'Verification cancelled',
        );
        return;
      }

      // Check for success verification status
      // We interpret the presence of non-null verification data as success ONLY if it's not an error event
      // Check for success verification status
      // We interpret the presence of non-null verification data as success ONLY if it's not an error event
      if (result['status'] == 'success' ||
          (result['data']?['verification'] != null &&
              result['data']?['verification']?['status'] != null)) {
        final productCode = result['data']?['productCode'];

        setState(() {
          if (productCode == 'drivers_license') {
            _driversLicenseVerified = true;
          } else if (productCode == 'nin') {
            // Assuming 'nin' is for identity verification as per launch params
            _identityVerified = true;
          }
        });

        // Handle success if both are verified
        if (_driversLicenseVerified && _identityVerified) {
          _handleSuccess();
        } else {
          CustomFlushbar.showSuccess(
            context: context,
            message:
                'Verification successful. Please complete the remaining step.',
          );
        }
      } else if (result['status'] == 'error' ||
          result['status'] == 'cancelled') {
        CustomFlushbar.showError(
          context: context,
          message: 'Verification failed or cancelled. Please try again.',
        );
      }
    });
  }

  void _handleSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountVerificationSuccessScreen(),
      ),
    );
  }

  Future<void> _launchQoreIDIdentity() async {
    // TODO: Replace with your actual QoreID Client ID
    // const String clientId = "KBC1C1YDB6ACWN2AB5PK";
    const String clientId = "NYPPI7J3M2CAROJ4U28O";

    if (clientId != "NYPPI7J3M2CAROJ4U28O") {
      CustomFlushbar.showError(
        context: context,
        message: 'QoreID Client ID not configured.',
      );
      return;
    }

    // Prepare applicant data with actual user information
    // IMPORTANT: QoreID SDK expects camelCase field names
    final applicantData = <String, dynamic>{
      'firstName': widget.firstName ?? '',
      'lastName': widget.lastName ?? '',
      'middleName': '', // Add middleName field
      'email': widget.email ?? '',
      'gender': '', // Add gender field
    };

    if (widget.phone != null && widget.phone!.isNotEmpty) {
      // Remove any non-digit characters and format properly
      String cleanPhone = widget.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      applicantData['phoneNumber'] = cleanPhone;
    } else {
      applicantData['phoneNumber'] = '';
    }

    if (widget.dob != null && widget.dob!.isNotEmpty) {
      // Convert MM/DD/YYYY to YYYY-MM-DD format if needed
      try {
        final parts = widget.dob!.split('/');
        if (parts.length == 3) {
          applicantData['dob'] = '${parts[2]}-${parts[0]}-${parts[1]}';
        }
      } catch (e) {
        debugPrint('Error parsing DOB: $e');
        applicantData['dob'] = '';
      }
    } else {
      applicantData['dob'] = '';
    }

    debugPrint('QoreID Applicant Data: $applicantData');
    debugPrint('QoreID Client ID: $clientId');
    debugPrint('QoreID Product Code: face_verification');

    final data = QoreidData(
      clientId: clientId,
      customerReference:
          "user_${DateTime.now().millisecondsSinceEpoch}", // Unique Ref
      productCode: "nin", // Try face verification first
      flowId: 0,
      addressData: {},
      applicantData: applicantData,
      ocrAcceptedDocuments: "",
      identityData: {},
    );

    try {
      debugPrint('Launching QoreID SDK...');
      await Qoreidsdk.launchQoreid(data);
      debugPrint('QoreID SDK launched successfully');
    } catch (e, stackTrace) {
      debugPrint("QoreID Launch Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to launch verification: $e',
      );
    }
  }

  Future<void> _launchQoreIDdriversLicense() async {
    // TODO: Replace with your actual QoreID Client ID
    const String clientId = "NYPPI7J3M2CAROJ4U28O";

    if (clientId != "NYPPI7J3M2CAROJ4U28O") {
      CustomFlushbar.showError(
        context: context,
        message: 'QoreID Client ID not configured.',
      );
      return;
    }

    // Prepare applicant data with actual user information
    // IMPORTANT: QoreID SDK expects camelCase field names
    final applicantData = <String, dynamic>{
      'firstName': widget.firstName ?? '',
      'lastName': widget.lastName ?? '',
      'middleName': '', // Add middleName field
      'email': widget.email ?? '',
      'gender': '', // Add gender field
    };

    if (widget.phone != null && widget.phone!.isNotEmpty) {
      // Remove any non-digit characters and format properly
      String cleanPhone = widget.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      applicantData['phoneNumber'] = cleanPhone;
    } else {
      applicantData['phoneNumber'] = '';
    }

    if (widget.dob != null && widget.dob!.isNotEmpty) {
      // Convert MM/DD/YYYY to YYYY-MM-DD format if needed
      try {
        final parts = widget.dob!.split('/');
        if (parts.length == 3) {
          applicantData['dob'] = '${parts[2]}-${parts[0]}-${parts[1]}';
        }
      } catch (e) {
        debugPrint('Error parsing DOB: $e');
        applicantData['dob'] = '';
      }
    } else {
      applicantData['dob'] = '';
    }

    debugPrint('QoreID Applicant Data: $applicantData');
    debugPrint('QoreID Client ID: $clientId');
    debugPrint('QoreID Product Code: face_verification');

    final data = QoreidData(
      clientId: clientId,
      customerReference:
          "user_${DateTime.now().millisecondsSinceEpoch}", // Unique Ref
      productCode: "drivers_license", // Try face verification first
      flowId: 0,
      addressData: {},
      applicantData: applicantData,
      ocrAcceptedDocuments: "",
      identityData: {},
    );

    try {
      debugPrint('Launching QoreID SDK...');
      await Qoreidsdk.launchQoreid(data);
      debugPrint('QoreID SDK launched successfully');
    } catch (e, stackTrace) {
      debugPrint("QoreID Launch Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to launch verification: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          ),
        ),
        centerTitle: true,
        title: Text(
          'KYC Verification',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              Text(
                'Please submit the following document to verify your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30.h),

              // Tile 1: Driver's License
              _buildVerificationTile(
                imagePath: 'assets/images/kyc.png',
                title: "Driver's License Verification",
                subtitle:
                    "To process your application, we require valid identification to confirm your eligibility to offer this service.",
                onTap: _driversLicenseVerified
                    ? () {}
                    : _launchQoreIDdriversLicense,
                isActionable: !_driversLicenseVerified,
                isVerified: _driversLicenseVerified,
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(color: Colors.grey[200], thickness: 1),
              ),

              // Tile 2: Identity Verification
              _buildVerificationTile(
                imagePath: 'assets/images/accountImage.png',
                title: "Identity verification",
                subtitle:
                    "Provide a clear and valid form of identification to verify your identity. This helps us ensure the safety and trust of everyone using our platform",
                onTap: _identityVerified ? () {} : _launchQoreIDIdentity,
                isActionable: !_identityVerified,
                isVerified: _identityVerified,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(color: Colors.grey[200], thickness: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActionable = false,
    bool isVerified = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          // Optional: Add subtle background if actionable
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(ConstColors.mainColor).withOpacity(0.1),
              ),
              padding: EdgeInsets.all(10.w),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.description,
                    color: Color(ConstColors.mainColor),
                  );
                },
              ),
            ),
            SizedBox(width: 16.w),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isVerified)
              Padding(
                padding: EdgeInsets.only(left: 8.w, top: 10.h),
                child: Icon(
                  Icons.check_circle,
                  size: 20.sp,
                  color: Colors.green,
                ),
              )
            else if (isActionable)
              Padding(
                padding: EdgeInsets.only(left: 8.w, top: 10.h),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
