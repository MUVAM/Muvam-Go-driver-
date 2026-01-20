import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/screens/kyc_verification_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/state_selection_screen.dart';
import 'package:muvam_rider/features/auth/presentation/screens/lga_selection_screen.dart';
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
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
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
                      'Please enter your information as it is on \nyour government issued ID',
                      style: ConstTextStyles.createAccountSubtitle.copyWith(
                        color: themeManager.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
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
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your first name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Middle name',
                        controller: middleNameController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your middle name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Last name',
                        controller: lastNameController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your last name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Date of birth',
                        controller: dobController,
                        backgroundColor: ConstColors.formFieldColor,
                        isDateField: true,
                        hintText: 'MM/DD/YYYY',
                        onTap: () => _selectDate(context, dobController),
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Email address',
                        controller: emailController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your email address',
                      ),
                      SizedBox(height: 20.h),
                      _buildStateField(themeManager),
                      SizedBox(height: 20.h),
                      _buildLgaField(themeManager),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Home Address',
                        controller: homeAddressController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your home address',
                      ),
                      SizedBox(height: 20.h),
                      _buildLocationField(themeManager),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Referral code (Optional)',
                        controller: referralController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter referral code if you have one',
                      ),
                      SizedBox(height: 40.h),
                      _buildContinueButton(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.locationFieldColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: locationController,
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tap to get current location',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  readOnly: true,
                  onTap: _getCurrentLocation,
                ),
              ),
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.my_location,
                    size: 20.sp,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        locationController.text = 'Getting location...';
      });

      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationController.clear();
          });
          if (!mounted) return;
          CustomFlushbar.showError(
            context: context,
            message: 'Location permission denied',
          );
          return;
        }
      }

      // Check if permission was permanently denied
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message:
              'Location permission permanently denied. Please enable in settings.',
        );
        return;
      }

      // Get position with better error handling
      Position? position;
      try {
        position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              Duration(seconds: 20), // Increased timeout
              onTimeout: () {
                throw TimeoutException(
                  'Location fetch timed out after 20 seconds',
                );
              },
            );
      } on TimeoutException catch (e) {
        AppLogger.log('Position timeout: $e');
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location request timed out. Please try again.',
        );
        return;
      }

      // Store location point immediately (this is most important)
      _locationPoint = 'POINT(${position.longitude} ${position.latitude})';
      AppLogger.log('Location Point (correct format): $_locationPoint');

      // Set default state using coordinates as fallback
      String fallbackCity =
          'City_${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}';
      _selectedState = fallbackCity;

      String address = '';
      bool geocodingSuccessful = false;

      // Try geocoding but don't fail if it doesn't work
      try {
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            AppLogger.log('Geocoding attempt ${attempt + 1}...');

            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            ).timeout(Duration(seconds: 10));

            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];

              // Extract city with multiple fallbacks
              String? city =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  place.subLocality;

              if (city != null && city.isNotEmpty) {
                _selectedState = city;
                AppLogger.log('Extracted city: $_selectedState');
              }

              // Build a readable address
              List<String> addressParts = [];

              if (place.street != null && place.street!.isNotEmpty) {
                addressParts.add(place.street!);
              }
              if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                addressParts.add(place.subLocality!);
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                addressParts.add(place.locality!);
              }
              if (place.administrativeArea != null &&
                  place.administrativeArea!.isNotEmpty) {
                addressParts.add(place.administrativeArea!);
              }
              if (place.country != null && place.country!.isNotEmpty) {
                addressParts.add(place.country!);
              }

              address = addressParts.join(', ');

              if (address.isEmpty && city != null) {
                address = city;
              }

              geocodingSuccessful = true;
              AppLogger.log('Geocoded address: $address');
              break;
            }
          } on TimeoutException catch (e) {
            AppLogger.log('Geocoding attempt ${attempt + 1} timed out: $e');
            if (attempt < 2) {
              await Future.delayed(Duration(seconds: 1));
            }
          } catch (e) {
            AppLogger.log('Geocoding attempt ${attempt + 1} failed: $e');
            if (attempt < 2) {
              await Future.delayed(Duration(seconds: 1));
            } else {
              break;
            }
          }
        }
      } catch (e) {
        AppLogger.log('Geocoding completely failed: $e');
        // Don't return here - we still have coordinates
      }

      // Update UI with whatever we have
      if (geocodingSuccessful && address.isNotEmpty) {
        setState(() {
          locationController.text = address;
        });

        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location captured successfully',
        );
      } else {
        // Use coordinates as display, but we still have _locationPoint and _selectedState
        setState(() {
          locationController.text =
              'Lat: ${position!.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });

        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location saved (GPS coordinates)',
        );
      }

      AppLogger.log('Final location point to send to backend: $_locationPoint');
      AppLogger.log('Final city to send to backend: $_selectedState');
    } on LocationServiceDisabledException catch (e) {
      AppLogger.log('Location services disabled: $e');
      setState(() {
        locationController.clear();
        _locationPoint = null;
      });

      if (!mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Location services are disabled. Please enable GPS.',
      );
    } catch (e) {
      AppLogger.log('Error getting location: $e');
      setState(() {
        locationController.clear();
        _locationPoint = null;
        _selectedState = null;
      });

      if (!mounted) return;

      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  Widget _buildStateField(ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
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
                stateController.text = result;
                _selectedLga = null;
                lgaController.clear();
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
                    stateController.text.isEmpty
                        ? 'Select State'
                        : stateController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: stateController.text.isEmpty
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

  Widget _buildLgaField(ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LGA',
          style: ConstTextStyles.fieldLabel.copyWith(
            color: themeManager.getTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _selectedState == null
              ? null
              : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LgaSelectionScreen(selectedState: _selectedState!),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _selectedLga = result;
                      lgaController.text = result;
                    });
                  }
                },
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: _selectedState == null
                  ? Colors.grey.shade200
                  : Color(ConstColors.locationFieldColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lgaController.text.isEmpty
                        ? (_selectedState == null
                              ? 'Select State first'
                              : 'Select LGA')
                        : lgaController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: lgaController.text.isEmpty
                          ? Colors.grey
                          : themeManager.getTextColor(context),
                    ),
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 5.w,
                    height: 5.h,
                    fit: BoxFit.contain,
                    colorFilter: _selectedState == null
                        ? ColorFilter.mode(Colors.grey, BlendMode.srcIn)
                        : null,
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

  // Inside _createAccount method in CreateAccountScreen

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

      // Token is already saved in ApiService.registerUser
      // Just retrieve it to verify and pass to next screen
      final accessToken = await ApiService.getToken();

      AppLogger.log("Retrieved Access Token from storage: $accessToken");

      if (accessToken == null || accessToken.isEmpty) {
        CustomFlushbar.showError(
          context: context,
          message: 'Failed to retrieve authentication token',
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KycVerificationScreen(token: accessToken),
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
