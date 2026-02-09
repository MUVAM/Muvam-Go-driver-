import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/auth/presentation/screens/upload_document_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/car_text_field.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/custom_bottom_sheet.dart';

class CarInformationScreen extends StatefulWidget {
  final bool showBackButton;

  const CarInformationScreen({super.key, this.showBackButton = false});

  @override
  State<CarInformationScreen> createState() => _CarInformationScreenState();
}

class _CarInformationScreenState extends State<CarInformationScreen> {
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController driverLicenseNumberController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? driverLicenseFile;
  bool isLoading = false;

  String? selectedCarName;
  String carNameDisplayText = 'Select car';

  String? selectedCarModel;
  String carModelDisplayText = 'Select model';

  String? selectedCarYear;
  String carYearDisplayText = 'Select year';

  String? selectedSeats;
  String seatsDisplayText = 'Select seats';

  String? selectedAC;
  String acDisplayText = 'Select';

  final List<String> carNames = ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes'];
  final List<String> carModels = ['Camry', 'Accord', 'Focus', 'X5', 'C-Class'];
  final List<String> carYears = [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
  ];
  final List<String> seatOptions = ['2', '4', '5', '7', '8'];
  final List<String> acOptions = ['Yes', 'No'];

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
                  SizedBox(height: 30.h),
                  if (widget.showBackButton)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            ConstImages.back,
                            width: 33.w,
                            height: 33.h,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Car information',
                            style: ConstTextStyles.createAccountTitle.copyWith(
                              color: themeManager.getTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 24.w),
                      ],
                    )
                  else
                    Text(
                      'Car information',
                      style: ConstTextStyles.createAccountTitle.copyWith(
                        color: themeManager.getTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  Text(
                    'Please enter your car details',
                    style: ConstTextStyles.createAccountSubtitle.copyWith(
                      color: themeManager.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
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
                      DropdownField(
                        label: 'Car name',
                        displayText: carNameDisplayText,
                        textColor: selectedCarName != null
                            ? Colors.black
                            : null,
                        onTap: () => _showCarNameBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car model',
                        displayText: carModelDisplayText,
                        textColor: selectedCarModel != null
                            ? Colors.black
                            : null,
                        onTap: () => _showCarModelBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car year',
                        displayText: carYearDisplayText,
                        textColor: selectedCarYear != null
                            ? Colors.black
                            : null,
                        onTap: () => _showCarYearBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Number of seats',
                        displayText: seatsDisplayText,
                        textColor: selectedSeats != null ? Colors.black : null,
                        onTap: () => _showSeatsBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      CarTextField(
                        label: 'License plate',
                        controller: licensePlateController,
                        hintText: 'AB-1234-XY',
                      ),
                      SizedBox(height: 20.h),
                      CarTextField(
                        label: 'Car color',
                        controller: colorController,
                        hintText: 'Yellow, red',
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'AC',
                        displayText: acDisplayText,
                        textColor: selectedAC != null ? Colors.black : null,
                        onTap: () => _showACBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      CarTextField(
                        label: 'Driver License Number',
                        controller: driverLicenseNumberController,
                        hintText: 'Enter your driver license number',
                      ),
                      SizedBox(height: 20.h),
                      // Driver License Upload Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver License Photo',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: themeManager.getTextColor(context),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _pickDriverLicense,
                            child: Container(
                              width: double.infinity,
                              height: 120.h,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: driverLicenseFile != null
                                      ? Color(ConstColors.mainColor)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                color: driverLicenseFile != null
                                    ? Color(
                                        ConstColors.mainColor,
                                      ).withOpacity(0.05)
                                    : Colors.grey.shade50,
                              ),
                              child: driverLicenseFile != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          child: Image.file(
                                            driverLicenseFile!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 40.sp,
                                          color: Colors.grey.shade400,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Tap to upload driver license',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),
                      GestureDetector(
                        onTap: isLoading ? null : _registerVehicle,
                        child: Container(
                          width: double.infinity,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: isLoading
                                ? Colors.grey
                                : Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: isLoading
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
          ],
        ),
      ),
    );
  }

  void _showCarNameBottomSheet(ThemeManager themeManager) {
    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Name',
      options: carNames,
      selectedValue: selectedCarName,
      onSelected: (value) {
        setState(() {
          selectedCarName = value;
          carNameDisplayText = value;
        });
      },
    );
  }

  void _showCarModelBottomSheet(ThemeManager themeManager) {
    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Model',
      options: carModels,
      selectedValue: selectedCarModel,
      onSelected: (value) {
        setState(() {
          selectedCarModel = value;
          carModelDisplayText = value;
        });
      },
    );
  }

  void _showCarYearBottomSheet(ThemeManager themeManager) {
    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Year',
      options: carYears,
      selectedValue: selectedCarYear,
      onSelected: (value) {
        setState(() {
          selectedCarYear = value;
          carYearDisplayText = value;
        });
      },
    );
  }

  void _showSeatsBottomSheet(ThemeManager themeManager) {
    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Number of Seats',
      options: seatOptions,
      selectedValue: selectedSeats,
      onSelected: (value) {
        setState(() {
          selectedSeats = value;
          seatsDisplayText = value;
        });
      },
    );
  }

  void _showACBottomSheet(ThemeManager themeManager) {
    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select AC Availability',
      options: acOptions,
      selectedValue: selectedAC,
      onSelected: (value) {
        setState(() {
          selectedAC = value;
          acDisplayText = value;
        });
      },
    );
  }

  Future<void> _pickDriverLicense() async {
    AppLogger.log('📸 User tapped to pick driver license image');
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          driverLicenseFile = File(pickedFile.path);
        });
        AppLogger.log('✅ Driver license image selected: ${pickedFile.path}');
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Driver license image selected',
        );
      } else {
        AppLogger.log('❌ No image selected');
      }
    } catch (e) {
      AppLogger.log('❌ Error picking driver license image: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to pick image: $e',
      );
    }
  }

  Future<void> _registerVehicle() async {
    AppLogger.log(
      '\n🚀 ========== STARTING VEHICLE REGISTRATION FLOW ==========',
    );
    AppLogger.log('📋 Step 1: Validating all required fields...');

    // Validate all car information fields
    if (selectedCarName == null ||
        selectedCarModel == null ||
        selectedCarYear == null ||
        selectedSeats == null ||
        licensePlateController.text.isEmpty ||
        colorController.text.isEmpty ||
        selectedAC == null) {
      AppLogger.log('❌ Validation failed: Missing car information fields');
      CustomFlushbar.showError(
        context: context,
        message: 'Please fill all car information fields',
      );
      return;
    }

    // Validate driver license fields
    if (driverLicenseNumberController.text.isEmpty) {
      AppLogger.log('❌ Validation failed: Driver license number is empty');
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter your driver license number',
      );
      return;
    }

    if (driverLicenseFile == null) {
      AppLogger.log('❌ Validation failed: Driver license file not uploaded');
      CustomFlushbar.showError(
        context: context,
        message: 'Please upload your driver license photo',
      );
      return;
    }

    AppLogger.log('✅ All fields validated successfully');
    AppLogger.log('📝 Car Name: $selectedCarName');
    AppLogger.log('📝 Car Model: $selectedCarModel');
    AppLogger.log('📝 Car Year: $selectedCarYear');
    AppLogger.log('📝 Seats: $selectedSeats');
    AppLogger.log('📝 License Plate: ${licensePlateController.text}');
    AppLogger.log('📝 Color: ${colorController.text}');
    AppLogger.log('📝 AC: $selectedAC');
    AppLogger.log(
      '📝 Driver License Number: ${driverLicenseNumberController.text}',
    );
    AppLogger.log('📝 Driver License File: ${driverLicenseFile!.path}');

    setState(() => isLoading = true);

    try {
      AppLogger.log('\n📋 Step 2: Retrieving authentication token...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        AppLogger.log('❌ Authentication token not found');
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication token not found. Please login again.',
        );
        setState(() => isLoading = false);
        return;
      }

      AppLogger.log('✅ Token retrieved successfully');
      AppLogger.log(
        '\n📋 Step 3: Calling uploadVerificationDocuments endpoint...',
      );
      AppLogger.log('🌐 Endpoint: /users/verification');
      AppLogger.log('📤 Uploading driver license for verification...');

      final verificationResult = await ApiService.uploadVerificationDocuments(
        driverLicenseFile: driverLicenseFile!,
        driverLicenseNumber: driverLicenseNumberController.text,
        token: token,
      );

      AppLogger.log('\n📥 Verification API Response received');
      AppLogger.log('Response: $verificationResult');

      if (!mounted) {
        AppLogger.log('⚠️ Widget unmounted, stopping flow');
        return;
      }

      if (verificationResult['success'] == true) {
        AppLogger.log('✅ Driver license verification SUCCESSFUL!');
        AppLogger.log('\n📋 Step 4: Navigating to Upload Documents Screen...');
        AppLogger.log(
          '🎯 Next screen: KycVerificationScreen (upload_document_screen.dart)',
        );
        AppLogger.log('📦 Passing car information to next screen...');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KycVerificationScreen(
              token: token,
              carMake: selectedCarName!,
              carModel: selectedCarModel!,
              carYear: selectedCarYear!,
              carSeats: selectedSeats!,
              licenseNumber: licenseNumberController.text,
              licensePlate: licensePlateController.text,
              carColor: colorController.text,
              isAcEnabled: selectedAC == 'Yes',
            ),
          ),
        );

        AppLogger.log('✅ Navigation to Upload Documents Screen successful');
        AppLogger.log(
          '========== VEHICLE REGISTRATION FLOW STEP 1 COMPLETE ==========\n',
        );
      } else {
        AppLogger.log('❌ Driver license verification FAILED');
        String errorMessage =
            verificationResult['message'] ??
            'Driver license verification failed';
        AppLogger.log('Error message: $errorMessage');

        CustomFlushbar.showError(context: context, message: errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ CRITICAL ERROR in vehicle registration flow');
      AppLogger.log('Error: $e');
      AppLogger.log('Stack trace: $stackTrace');

      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        AppLogger.log('🔄 Loading state reset');
      }
    }
  }
}
