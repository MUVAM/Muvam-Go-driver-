import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/create_location_field.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/account_text_field.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/state_field.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/lga_field.dart';
import 'package:muvam_rider/layouts/presentation/shared/continue_button.dart';

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
  final TextEditingController stateController = TextEditingController();
  final TextEditingController lgaController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? _selectedState;
  String? _selectedLga;
  String? _locationPoint;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    firstNameController.addListener(_updateButtonState);
    lastNameController.addListener(_updateButtonState);
    dobController.addListener(_updateButtonState);
    emailController.addListener(_updateButtonState);
    stateController.addListener(_updateButtonState);
    lgaController.addListener(_updateButtonState);
    homeAddressController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        dobController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        _selectedState != null &&
        _selectedLga != null &&
        homeAddressController.text.isNotEmpty &&
        _locationPoint != null;
  }

  @override
  void dispose() {
    firstNameController.removeListener(_updateButtonState);
    lastNameController.removeListener(_updateButtonState);
    dobController.removeListener(_updateButtonState);
    emailController.removeListener(_updateButtonState);
    stateController.removeListener(_updateButtonState);
    lgaController.removeListener(_updateButtonState);
    homeAddressController.removeListener(_updateButtonState);

    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    stateController.dispose();
    lgaController.dispose();
    homeAddressController.dispose();
    referralController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        backgroundColor: AppColors.kWhiteColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 25.h),
                    Center(
                      child: MuvamTexts.headlineSmall24(
                        context,
                        text: 'Create Account',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Center(
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text:
                            'Please enter your information as it is on \nyour government issued ID',
                        isTextWidget: true,
                        fontWeight: FontWeight.w400,
                        color: AppColors.kGreyColor,
                        center: true,
                      ),
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
                        AccountTextField(
                          label: 'First name',
                          controller: firstNameController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter your first name',
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Middle name',
                          controller: middleNameController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter your middle name',
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Last name',
                          controller: lastNameController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter your last name',
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Date of birth',
                          controller: dobController,
                          backgroundColor: AppColors.kFormFieldColor,
                          isDateField: true,
                          hintText: 'MM/DD/YYYY',
                          onTap: () => _selectDate(context, dobController),
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Email address',
                          controller: emailController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter your email address',
                        ),
                        SizedBox(height: 20.h),
                        StateField(
                          controller: stateController,
                          selectedState: _selectedState,
                          onStateSelected: (state) {
                            setState(() {
                              _selectedState = state;
                            });
                          },
                          onClearLga: () {
                            setState(() {
                              _selectedLga = null;
                              lgaController.clear();
                            });
                          },
                          themeManager: themeManager,
                        ),
                        SizedBox(height: 20.h),
                        LgaField(
                          controller: lgaController,
                          selectedState: _selectedState,
                          selectedLga: _selectedLga,
                          onLgaSelected: (lga) {
                            setState(() {
                              _selectedLga = lga;
                            });
                          },
                          themeManager: themeManager,
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Home Address',
                          controller: homeAddressController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter your home address',
                        ),
                        SizedBox(height: 20.h),
                        CreateLocationField(
                          controller: locationController,
                          onLocationPointChanged: (point) {
                            setState(() {
                              _locationPoint = point;
                            });
                          },
                          onStateChanged: (state) {
                            setState(() {
                              _selectedState = state;
                              stateController.text = state;
                            });
                          },
                          themeManager: themeManager,
                        ),
                        SizedBox(height: 20.h),
                        AccountTextField(
                          label: 'Referral code (Optional)',
                          controller: referralController,
                          backgroundColor: AppColors.kFormFieldColor,
                          hintText: 'Enter referral code if you have one',
                        ),
                        SizedBox(height: 40.h),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: ContinueButton(
                  isEnabled: _isFormValid && !_isLoading,
                  isLoading: _isLoading,
                  onPressed: _createAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (_locationPoint == null || _locationPoint!.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please set your location first',
      );
      return;
    }

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
      lga: _selectedLga!,
      homeAddress: homeAddressController.text.trim(),
      city: _selectedState!,
      location: _locationPoint!,
      referralCode: referralController.text.trim().isEmpty
          ? null
          : referralController.text.trim(),
      serviceType: widget.serviceType ?? 'taxi',
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      AppLogger.log("Registration Success: ${result['success']}");

      final accessToken = await ApiService.getToken();

      AppLogger.log("Retrieved Access Token from storage: $accessToken");

      if (accessToken == null || accessToken.isEmpty) {
        CustomFlushbar.showError(
          context: context,
          message: 'Failed to retrieve authentication token',
        );
        return;
      }
      context.pushNamed(
        AppRoutes.kycVerificationPage.name,
        extra: {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': widget.phoneNumber,
          'dob': dobController.text.trim(),
        },
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.kMainColor,
              onPrimary: AppColors.kWhiteColor,
              onSurface: AppColors.kBlackColor,
              surface: AppColors.kWhiteColor,
            ),
            dialogBackgroundColor: AppColors.kWhiteColor,
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
