import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/screens/kyc_verification_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/state_selection_screen.dart';
import '../widgets/account_text_field.dart';

class CreateAccountScreen extends StatefulWidget {
  final String phoneNumber;
  final String? serviceType;

  const CreateAccountScreen({
    super.key,
    required this.phoneNumber,
    this.serviceType,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  String? _selectedState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Add listeners to update button state
    firstNameController.addListener(_updateButtonState);
    lastNameController.addListener(_updateButtonState);
    dobController.addListener(_updateButtonState);
    emailController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        dobController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        _selectedState != null;
  }

  @override
  void dispose() {
    firstNameController.removeListener(_updateButtonState);
    lastNameController.removeListener(_updateButtonState);
    dobController.removeListener(_updateButtonState);
    emailController.removeListener(_updateButtonState);

    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    locationController.dispose();
    referralController.dispose();
    super.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 25.h),
                Center(
                  child: Text(
                    'Create Account',
                    style: ConstTextStyles.createAccountTitle.copyWith(
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Center(
                  child: Text(
                    'Please enter your correct details as it is \non your government issued document.',
                    style: ConstTextStyles.createAccountSubtitle.copyWith(
                      color: themeManager.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                AccountTextField(
                  label: 'First Name',
                  controller: firstNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Middle Name (Optional)',
                  controller: middleNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Date of Birth',
                  controller: dobController,
                  backgroundColor: ConstColors.formFieldColor,
                  isDateField: true,
                  onTap: () => _selectDate(context, dobController),
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Email Address',
                  controller: emailController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildLocationField(themeManager),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Referral Code (Optional)',
                  controller: referralController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 40.h),
                _buildContinueButton(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: ConstTextStyles.fieldLabel.copyWith(
            color: themeManager.getTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StateSelectionScreen(),
              ),
            );

            if (result != null) {
              setState(() {
                _selectedState = result;
                locationController.text = result;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: Color(ConstColors.locationFieldColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locationController.text.isEmpty
                        ? 'Select State'
                        : locationController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: locationController.text.isEmpty
                          ? Colors.grey
                          : themeManager.getTextColor(context),
                    ),
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 5.w,
                    height: 5.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _isFormValid && !_isLoading;

    return GestureDetector(
      onTap: isEnabled ? _createAccount : null,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: isEnabled
              ? Color(ConstColors.mainColor)
              : Colors.grey.shade300,
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
    );
  }

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

    final result = await ApiService.registerUser(
      firstName: firstNameController.text.trim(),
      middleName: middleNameController.text.trim().isEmpty
          ? null
          : middleNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phoneNumber: widget.phoneNumber,
      dateOfBirth: dobController.text.trim(),
      city: _selectedState!,
      location: 'POINT(7.4069943 6.8720015)',
      serviceType: widget.serviceType ?? 'taxi',
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              KycVerificationScreen(token: result['data']['token'] ?? ''),
        ),
      );
    } else {
      if (!mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: result['message'] ?? 'Registration failed',
      );
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(ConstColors.mainColor),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String month = picked.month.toString().padLeft(2, '0');
      String day = picked.day.toString().padLeft(2, '0');
      controller.text = "$month/$day/${picked.year}";
    }
  }
}
