import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/screens/document_verification_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/services/api_service.dart';
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
  File? registrationDoc;
  File? insuranceDoc;
  List<File> vehiclePhotos = [];
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

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
                      GestureDetector(
                        onTap: _pickRegistrationDoc,
                        child: Container(
                          width: 353.w,
                          height: 120.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: registrationDoc != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.file(
                                        registrationDoc!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4.h,
                                      right: 4.w,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => registrationDoc = null,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 40.sp,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Upload Registration Doc',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: _pickInsuranceDoc,
                        child: Container(
                          width: 353.w,
                          height: 120.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: insuranceDoc != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.file(
                                        insuranceDoc!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4.h,
                                      right: 4.w,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => insuranceDoc = null),
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 40.sp,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Upload Insurance Doc',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: _pickVehiclePhotos,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: vehiclePhotos.isNotEmpty
                              ? Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: vehiclePhotos.asMap().entries.map((
                                    entry,
                                  ) {
                                    int index = entry.key;
                                    File photo = entry.value;
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                          child: Image.file(
                                            photo,
                                            width: 80.w,
                                            height: 80.h,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 2.h,
                                          right: 2.w,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () =>
                                                  vehiclePhotos.removeAt(index),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(2.w),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                )
                              : Container(
                                  height: 120.h,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 40.sp,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Upload Vehicle Photos',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
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

  Future<void> _pickRegistrationDoc() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 40,
    );
    if (image != null) {
      setState(() {
        registrationDoc = File(image.path);
      });
    }
  }

  Future<void> _pickInsuranceDoc() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 40,
    );
    if (image != null) {
      setState(() {
        insuranceDoc = File(image.path);
      });
    }
  }

  Future<void> _pickVehiclePhotos() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 40,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (images.isNotEmpty) {
      setState(() {
        vehiclePhotos = images.map((img) => File(img.path)).toList();
      });
    }
  }

  Future<void> _registerVehicle() async {
    AppLogger.log('=== REGISTER VEHICLE DEBUG START ===');
    AppLogger.log('Car Name: $selectedCarName');
    AppLogger.log('Car Model: $selectedCarModel');
    AppLogger.log('Car Year: $selectedCarYear');
    AppLogger.log('Number of Seats: $selectedSeats');
    AppLogger.log('License Plate: ${licensePlateController.text}');
    AppLogger.log('Color: ${colorController.text}');
    AppLogger.log('AC: $selectedAC');

    if (selectedCarName == null ||
        selectedCarModel == null ||
        selectedCarYear == null ||
        selectedSeats == null ||
        licensePlateController.text.isEmpty ||
        colorController.text.isEmpty ||
        selectedAC == null ||
        registrationDoc == null ||
        insuranceDoc == null ||
        vehiclePhotos.length < 3) {
      AppLogger.log('Validation failed - missing fields');
      String message;
      if (vehiclePhotos.length < 3) {
        message = 'Please upload at least 3 vehicle photos';
      } else if (selectedAC == null) {
        message = 'Please select AC availability';
      } else if (selectedSeats == null) {
        message = 'Please select number of seats';
      } else {
        message = 'Please fill all fields and upload all documents';
      }
      CustomFlushbar.showError(context: context, message: message);
      return;
    }

    AppLogger.log('All fields validated successfully');
    setState(() {
      isLoading = true;
    });

    try {
      AppLogger.log('Getting auth token from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      AppLogger.log('Token found: ${token != null}');
      if (token != null) {
        AppLogger.log('Token preview: ${token.substring(0, 20)}...');
      }

      if (token != null && mounted) {
        AppLogger.log('Calling ApiService.registerVehicle...');
        final result = await ApiService.registerVehicle(
          make: selectedCarName!,
          modelType: selectedCarModel!,
          seats: selectedSeats!,
          year: selectedCarYear!,
          licenseNumber: licenseNumberController.text,
          color: colorController.text,
          licensePlate: licensePlateController.text,
          registrationDoc: registrationDoc!,
          insuranceDoc: insuranceDoc!,
          vehiclePhotos: vehiclePhotos,
          token: token,
          ac: selectedAC == 'Yes',
        );

        AppLogger.log('API Response received:');
        AppLogger.log('Success: ${result['success']}');
        AppLogger.log('Message: ${result['message']}');
        AppLogger.log('Full result: $result');

        if (!mounted) return;

        if (result['success'] == true) {
          AppLogger.log(
            'Vehicle registration successful - navigating to DocumentVerificationSuccessScreen',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentVerificationSuccessScreen(),
            ),
          );
        } else {
          AppLogger.log('Vehicle registration failed: ${result['message']}');
          String errorMessage = result['message'] ?? 'Registration failed';

          if (errorMessage.contains('user not found') ||
              errorMessage.contains('unauthorized')) {
            errorMessage = 'Your session has expired. Please login again.';
            await prefs.remove('auth_token');
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
            return;
          }
          CustomFlushbar.showError(context: context, message: errorMessage);
        }
      } else {
        AppLogger.log('No auth token found');
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication token not found. Please login again.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.log('EXCEPTION in _registerVehicle: $e');
      AppLogger.log('Stack trace: $stackTrace');
      CustomFlushbar.showError(context: context, message: 'Error: $e');
    } finally {
      AppLogger.log('Setting isLoading to false');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      AppLogger.log('=== REGISTER VEHICLE DEBUG END ===\n');
    }
  }
}
