import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/theme_manager.dart';
import '../services/api_service.dart';
import 'kyc_verification_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  final String phoneNumber;
  
  const CreateAccountScreen({super.key, required this.phoneNumber});

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
                _buildTextField('First Name', firstNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Middle Name (Optional)', middleNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Last Name', lastNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Date of Birth', dobController, ConstColors.formFieldColor, isDateField: true),
                SizedBox(height: 20.h),
                _buildTextField('Email Address', emailController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildLocationField(),
                SizedBox(height: 20.h),
                _buildTextField('City', cityController, ConstColors.locationFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Referral Code (Optional)', referralController, ConstColors.formFieldColor),
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

  Future<void> _createAccount() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dobController.text.isEmpty ||
        locationController.text.isEmpty ||
        cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.registerUser(
      firstName: firstNameController.text,
      middleName: middleNameController.text.isEmpty ? null : middleNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
      phoneNumber: widget.phoneNumber,
      dateOfBirth: dobController.text,
      city: cityController.text,
      location: 'POINT(7.4069943 6.8720015)', // Default location for Enugu
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KycVerificationScreen(
            token: result['data']['token'] ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    }
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: ConstTextStyles.fieldLabel,
        ),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final suggestion = _locationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on, size: 20.sp, color: Color(ConstColors.mainColor)),
                  title: Text(
                    suggestion,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
                  ),
                  onTap: () => _selectLocation(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, int backgroundColor, {bool isDateField = false, bool hasDropdown = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ConstTextStyles.fieldLabel,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(backgroundColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isDateField,
                  obscureText: isPassword,
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  ),
                  onTap: isDateField ? () => _selectDate(context, controller) : null,
                ),
              ),
              if (hasDropdown)
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(Icons.arrow_drop_down, size: 20.sp),
                ),
            ],
          ),
        ),
      ],
    );
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
        'Lagos, Nigeria', 'Abuja, Nigeria', 'Kano, Nigeria', 'Ibadan, Nigeria',
        'Port Harcourt, Nigeria', 'Benin City, Nigeria', 'Kaduna, Nigeria',
        'Jos, Nigeria', 'Ilorin, Nigeria', 'Enugu, Nigeria', 'Aba, Nigeria',
        'Onitsha, Nigeria', 'Warri, Nigeria', 'Sokoto, Nigeria', 'Calabar, Nigeria',
        'Uyo, Nigeria', 'Akure, Nigeria', 'Bauchi, Nigeria', 'Minna, Nigeria',
        'Gombe, Nigeria', 'Nsukka, Enugu', 'Ikeja, Lagos', 'Victoria Island, Lagos',
        'Lekki, Lagos', 'Surulere, Lagos', 'Yaba, Lagos', 'Ajah, Lagos',
      ];
      
      for (String location in nigerianStates) {
        if (location.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(location);
        }
      }
      
      try {
        List<Location> locations = await locationFromAddress(query + ", Nigeria");
        for (Location location in locations.take(3)) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String address = '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
    }
  }
}