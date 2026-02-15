import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/vehicles/data/provider/vehicle_provider.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/text_styles.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
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

  final List<String> seatOptions = ['2', '4', '5', '7', '8'];
  final List<String> acOptions = ['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    AppLogger.log('🔄 Loading vehicle data...', tag: 'CAR_INFO');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final vehicleProvider = Provider.of<VehicleProvider>(
        context,
        listen: false,
      );
      await vehicleProvider.fetchVehicleData(token);

      if (mounted) {
        setState(() {});
      }
    } else {
      AppLogger.log('⚠️ No auth token found', tag: 'CAR_INFO');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final vehicleProvider = Provider.of<VehicleProvider>(context);

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
                        onTap: () => _showCarNameBottomSheet(
                          themeManager,
                          vehicleProvider,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car model',
                        displayText: carModelDisplayText,
                        textColor: selectedCarModel != null
                            ? Colors.black
                            : null,
                        onTap: () => _showCarModelBottomSheet(
                          themeManager,
                          vehicleProvider,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car year',
                        displayText: carYearDisplayText,
                        textColor: selectedCarYear != null
                            ? Colors.black
                            : null,
                        onTap: () => _showCarYearBottomSheet(
                          themeManager,
                          vehicleProvider,
                        ),
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

  void _showCarNameBottomSheet(
    ThemeManager themeManager,
    VehicleProvider vehicleProvider,
  ) {
    final options = vehicleProvider.carMakes.isNotEmpty
        ? vehicleProvider.carMakes
        : ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes'];

    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Name',
      options: options,
      selectedValue: selectedCarName,
      onSelected: (value) {
        setState(() {
          selectedCarName = value;
          carNameDisplayText = value;
        });
      },
    );
  }

  void _showCarModelBottomSheet(
    ThemeManager themeManager,
    VehicleProvider vehicleProvider,
  ) {
    final options = vehicleProvider.carModels.isNotEmpty
        ? vehicleProvider.carModels
        : ['Camry', 'Accord', 'Focus', 'X5', 'C-Class'];

    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Model',
      options: options,
      selectedValue: selectedCarModel,
      onSelected: (value) {
        setState(() {
          selectedCarModel = value;
          carModelDisplayText = value;
        });
      },
    );
  }

  void _showCarYearBottomSheet(
    ThemeManager themeManager,
    VehicleProvider vehicleProvider,
  ) {
    final options = vehicleProvider.carYears.isNotEmpty
        ? vehicleProvider.carYears
        : ['2024', '2023', '2022', '2021', '2020', '2019'];

    CustomBottomSheet.showSelectionBottomSheet(
      context: context,
      themeManager: themeManager,
      title: 'Select Car Year',
      options: options,
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

  Future<void> _registerVehicle() async {
    AppLogger.log(
      '\n🚀 ========== STARTING VEHICLE REGISTRATION FLOW ==========',
    );
    AppLogger.log('📋 Step 1: Validating all required fields...');

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

    AppLogger.log('✅ All fields validated successfully');
    AppLogger.log('📝 Car Name: $selectedCarName');
    AppLogger.log('📝 Car Model: $selectedCarModel');
    AppLogger.log('📝 Car Year: $selectedCarYear');
    AppLogger.log('📝 Seats: $selectedSeats');
    AppLogger.log('📝 License Plate: ${licensePlateController.text}');
    AppLogger.log('📝 Color: ${colorController.text}');
    AppLogger.log('📝 AC: $selectedAC');

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
        return;
      }

      AppLogger.log('✅ Token retrieved successfully');
      AppLogger.log('\n📋 Step 3: Navigating to Upload Documents Screen...');
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
      AppLogger.log('========== CAR INFORMATION STEP COMPLETE ==========\n');
    } catch (e, stackTrace) {
      AppLogger.log('❌ CRITICAL ERROR in vehicle registration flow');
      AppLogger.log('Error: $e');
      AppLogger.log('Stack trace: $stackTrace');

      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }
}
