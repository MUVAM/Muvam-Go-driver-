import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:country_picker/country_picker.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/presentation/screens/otp_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String? serviceType;
  const OnboardingScreen({super.key, this.serviceType});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String countryCode = '+234';
  String countryFlag = '🇳🇬';
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  bool _isValidPhone() {
    return phoneController.text.length == 10;
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _sendOtp() async {
    String fullPhoneNumber = countryCode + phoneController.text;

    setState(() => _isLoading = true);

    final result = await ApiService.sendOtp(fullPhoneNumber);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phoneNumber: fullPhoneNumber,
            serviceType: widget.serviceType,
          ),
        ),
      );
    } else {
      CustomFlushbar.showError(
        context: context,
        message: result['message'] ?? 'Failed to send OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(
                  ConstImages.onboardCar,
                  width: 411.w,
                  height: 411.h,
                ),
                // SizedBox(height: 2.h),
                Text(
                  'Enter your phone number',
                  style: ConstTextStyles.boldTitle.copyWith(
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'We will send you a validation code',
                  style: ConstTextStyles.lightSubtitle.copyWith(
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 25.h),
                Container(
                  width: 353.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.fieldColor).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            onSelect: (Country country) {
                              setState(() {
                                countryCode = '+${country.phoneCode}';
                                countryFlag = country.flagEmoji;
                              });
                            },
                            countryListTheme: CountryListThemeData(
                              borderRadius: BorderRadius.circular(8.r),
                              // Search field styling
                              searchTextStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              inputDecoration: InputDecoration(
                                hintText: 'Search location',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                  height: 1.0,
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: Image.asset(
                                    'assets/images/search.png',
                                    width: 20.w,
                                    height: 20.h,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                              // Country list item styling
                              textStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              bottomSheetHeight: 500.h,
                              backgroundColor: Colors.white,
                            ),
                            // Show phone code in the list
                            showPhoneCode: true,
                          );
                        },
                        child: Container(
                          width: 85.w,
                          height: 42.h,
                          margin: EdgeInsets.only(left: 4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                countryFlag,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              SizedBox(width: 2.w),
                              Flexible(
                                child: Text(
                                  countryCode,
                                  style: ConstTextStyles.inputText.copyWith(
                                    fontSize: 14.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, size: 14.sp),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: ConstTextStyles.inputText,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 15.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 95.h),
                GestureDetector(
                  onTap: (_isValidPhone() && !_isLoading)
                      ? _sendOtp
                      : null,
                  child: Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _isValidPhone() && !_isLoading
                          ? Color(ConstColors.mainColor)
                          : Color(ConstColors.fieldColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
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
        ),
      ),
    );
  }
}
