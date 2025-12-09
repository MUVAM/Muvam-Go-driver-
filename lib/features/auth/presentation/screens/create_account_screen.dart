import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/screens/kyc_verification_screen.dart';
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
  final TextEditingController cityController = TextEditingController();
  bool _isLoading = false;
  List<String> _locationSuggestions = [];
  bool _showLocationSuggestions = false;

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
                SizedBox(height: 40.h),
                Text(
                  'Create Account',
                  style: ConstTextStyles.createAccountTitle.copyWith(
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your correct details as it is on your government issued document.',
                  style: ConstTextStyles.createAccountSubtitle.copyWith(
                    color: themeManager.getSecondaryTextColor(context),
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
                _buildLocationField(),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'City',
                  controller: cityController,
                  backgroundColor: ConstColors.locationFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Referral Code (Optional)',
                  controller: referralController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: _isLoading ? null : _createAccount,
                  child: Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: ConstTextStyles.fieldLabel),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.locationFieldColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: locationController,
            style: ConstTextStyles.inputText,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 15.h,
              ),
            ),
            onChanged: _searchLocations,
          ),
        ),
        if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 5.h),
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final suggestion = _locationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_on,
                    size: 20.sp,
                    color: Color(ConstColors.mainColor),
                  ),
                  title: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () => _selectLocation(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _createAccount() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dobController.text.isEmpty ||
        locationController.text.isEmpty ||
        cityController.text.isEmpty) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please fill all required fields',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.registerUser(
      firstName: firstNameController.text,
      middleName: middleNameController.text.isEmpty
          ? null
          : middleNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
      phoneNumber: widget.phoneNumber,
      dateOfBirth: dobController.text,
      city: cityController.text,
      location: 'POINT(7.4069943 6.8720015)',
      serviceType: widget.serviceType ?? 'taxi',
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              KycVerificationScreen(token: result['data']['token'] ?? ''),
        ),
      );
    } else {
      CustomFlushbar.showError(
        context: context,
        message: result['message'] ?? 'Registration failed',
      );
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 2) {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    try {
      List<String> suggestions = [];

      List<String> nigerianStates = [
        'Lagos, Nigeria',
        'Abuja, Nigeria',
        'Kano, Nigeria',
        'Ibadan, Nigeria',
        'Port Harcourt, Nigeria',
        'Benin City, Nigeria',
        'Kaduna, Nigeria',
        'Jos, Nigeria',
        'Ilorin, Nigeria',
        'Enugu, Nigeria',
        'Aba, Nigeria',
        'Onitsha, Nigeria',
        'Warri, Nigeria',
        'Sokoto, Nigeria',
        'Calabar, Nigeria',
        'Uyo, Nigeria',
        'Akure, Nigeria',
        'Bauchi, Nigeria',
        'Minna, Nigeria',
        'Gombe, Nigeria',
        'Nsukka, Enugu',
        'Ikeja, Lagos',
        'Victoria Island, Lagos',
        'Lekki, Lagos',
        'Surulere, Lagos',
        'Yaba, Lagos',
        'Ajah, Lagos',
      ];

      for (String location in nigerianStates) {
        if (location.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(location);
        }
      }

      try {
        List<Location> locations = await locationFromAddress("$query, Nigeria");
        for (Location location in locations.take(3)) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String address =
                '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
                    .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
            if (address.isNotEmpty && !suggestions.contains(address)) {
              suggestions.add(address);
            }
          }
        }
      } catch (e) {
        // Geocoding failed, continue with filtered suggestions
      }

      setState(() {
        _locationSuggestions = suggestions.take(8).toList();
        _showLocationSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
    }
  }

  void _selectLocation(String location) {
    setState(() {
      locationController.text = location;
      _locationSuggestions = [];
      _showLocationSuggestions = false;
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text =
          "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
    }
  }
}
