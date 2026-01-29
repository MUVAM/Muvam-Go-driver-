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
  const KycVerificationPage({super.key});

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listenToResults();
  }

  void _listenToResults() {
    Qoreidsdk.onResult((result) async {
      debugPrint('QoreID Result: $result');
      if (result['status'] == 'success' ||
          (result['data']?['verification'] != null)) {
        // Handle success
        _handleSuccess();
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

  Future<void> _launchQoreID() async {
    // TODO: Replace with your actual QoreID Client ID
    const String clientId = "YOUR_CLIENT_ID_HERE";

    if (clientId == "YOUR_CLIENT_ID_HERE") {
      CustomFlushbar.showError(
        context: context,
        message: 'QoreID Client ID not configured.',
      );
      return;
    }

    final data = QoreidData(
      clientId: clientId,
      customerReference:
          "user_${DateTime.now().millisecondsSinceEpoch}", // Unique Ref
      productCode:
          "face_verification", // Assuming face verification based on "Identity verification"
      flowId: 0,
      addressData: {},
      applicantData: {},
      ocrAcceptedDocuments: "",
      identityData: {},
    );

    try {
      await Qoreidsdk.launchQoreid(data);
    } catch (e) {
      debugPrint("QoreID Launch Error: $e");
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
            child: SvgPicture.asset(
              'assets/svg/back-chevron.svg', // Assuming this exists or similar
              colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              fit: BoxFit.contain,
            ),
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
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30.h),

              // Tile 1: Driver's License
              _buildVerificationTile(
                imagePath: 'assets/images/kyc.png',
                title: "Driver's License Verification",
                subtitle:
                    "To process your application we require valid identification to confirm your availability to offer this service",
                onTap: () {
                  // No specific action defined for this tile in requirements
                },
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(color: Colors.grey[200], thickness: 1),
              ),

              // Tile 2: Identity Verification
              _buildVerificationTile(
                imagePath: 'assets/images/avatar.png',
                title: "Identity verification",
                subtitle:
                    "Please provide a clear and valid form of identification to verify your identity, this helps us to verify who you are",
                onTap: _launchQoreID,
                isActionable: true,
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
            if (isActionable)
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
