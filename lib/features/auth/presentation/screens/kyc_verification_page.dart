import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/verification_tile_widget.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
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

      if (result['code'] == 'E_USER_CANCELED' ||
          result['event'] == 'ERROR_RESULT' ||
          result['message'] == 'User canceled') {
        CustomFlushbar.showError(
          context: context,
          message: result['message'] ?? 'Verification cancelled',
        );
        _handleSuccess();

        return;
      }

      if (result['status'] == 'success' ||
          (result['data']?['verification'] != null &&
              result['data']?['verification']?['status'] != null)) {
        final productCode = result['data']?['productCode'];

        setState(() {
          if (productCode == 'drivers_license') {
            _driversLicenseVerified = true;
          } else if (productCode == 'nin') {
            _identityVerified = true;
          }
        });

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
        _handleSuccess();
      }
    });
  }

  void _handleSuccess() {
    context.pushReplacementNamed(AppRoutes.accountVerificationSuccess.name);
  }

  Future<void> _launchQoreIDIdentity() async {
    const String clientId = "NYPPI7J3M2CAROJ4U28O";

    if (clientId != "NYPPI7J3M2CAROJ4U28O") {
      CustomFlushbar.showError(
        context: context,
        message: 'QoreID Client ID not configured.',
      );
      return;
    }

    final applicantData = <String, dynamic>{
      'firstName': widget.firstName ?? '',
      'lastName': widget.lastName ?? '',
      'middleName': '',
      'email': widget.email ?? '',
      'gender': '',
    };

    if (widget.phone != null && widget.phone!.isNotEmpty) {
      String cleanPhone = widget.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      applicantData['phoneNumber'] = cleanPhone;
    } else {
      applicantData['phoneNumber'] = '';
    }

    if (widget.dob != null && widget.dob!.isNotEmpty) {
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
      customerReference: "user_${DateTime.now().millisecondsSinceEpoch}",
      productCode: "nin",
      flowId: 1266,
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
    const String clientId = "NYPPI7J3M2CAROJ4U28O";

    if (clientId != "NYPPI7J3M2CAROJ4U28O") {
      CustomFlushbar.showError(
        context: context,
        message: 'QoreID Client ID not configured.',
      );
      return;
    }

    final applicantData = <String, dynamic>{
      'firstName': widget.firstName ?? '',
      'lastName': widget.lastName ?? '',
      'middleName': '',
      'email': widget.email ?? '',
      'gender': '',
    };

    if (widget.phone != null && widget.phone!.isNotEmpty) {
      String cleanPhone = widget.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      applicantData['phoneNumber'] = cleanPhone;
    } else {
      applicantData['phoneNumber'] = '';
    }

    if (widget.dob != null && widget.dob!.isNotEmpty) {
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
      customerReference: "user_${DateTime.now().millisecondsSinceEpoch}",
      productCode: "drivers_license",
      flowId: 1266,
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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: EdgeInsets.only(left: 12.w, bottom: 12.h),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      Center(
                        child: MuvamTexts.titleMedium18(
                          context,
                          text: 'KYC Verification',
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlackColor,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 245.w,
                          child: MuvamTexts.bodyMedium14(
                            context,
                            text:
                                'Please submit the following document to verify your profile',
                            center: true,
                            color: AppColors.kBlackColor,
                            maxLines: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              VerificationTileWidget(
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
                child: Divider(color: AppColors.kGreyColor, thickness: 1),
              ),
              VerificationTileWidget(
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
                child: Divider(color: AppColors.kGreyColor, thickness: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
