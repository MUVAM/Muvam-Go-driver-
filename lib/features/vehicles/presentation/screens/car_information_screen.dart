import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/vehicles/data/provider/vehicle_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
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
                          child: MuvamTexts.headlineSmall24(
                            context,
                            text: 'Car information',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlackColor,
                            center: true,
                          ),
                        ),
                        SizedBox(width: 24.w),
                      ],
                    )
                  else
                    MuvamTexts.headlineSmall24(
                      context,
                      text: 'Car information',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlackColor,
                      center: true,
                    ),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'Please enter your car details',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kGreyColor,
                    center: true,
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownField(
                        label: 'Car name',
                        displayText: carNameDisplayText,
                        textColor: selectedCarName != null
                            ? AppColors.kBlackColor
                            : null,
                        onTap: () => _showCarNameBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car model',
                        displayText: carModelDisplayText,
                        textColor: selectedCarModel != null
                            ? AppColors.kBlackColor
                            : null,
                        onTap: () => _showCarModelBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Car year',
                        displayText: carYearDisplayText,
                        textColor: selectedCarYear != null
                            ? AppColors.kBlackColor
                            : null,
                        onTap: () => _showCarYearBottomSheet(themeManager),
                      ),
                      SizedBox(height: 20.h),
                      DropdownField(
                        label: 'Number of seats',
                        displayText: seatsDisplayText,
                        textColor: selectedSeats != null
                            ? AppColors.kBlackColor
                            : null,
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
                        textColor: selectedAC != null
                            ? AppColors.kBlackColor
                            : null,
                        onTap: () => _showACBottomSheet(themeManager),
                      ),
                      SizedBox(height: 40.h),
                      GestureDetector(
                        onTap: isLoading ? null : _registerVehicle,
                        child: Container(
                          width: double.infinity,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: isLoading
                                ? AppColors.kGreyColor
                                : AppColors.kMainColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.kWhiteColor,
                                  )
                                : MuvamTexts.button16(
                                    context,
                                    text: 'Continue',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kWhiteColor,
                                  ),
                          ),
                        ),
                      ),
                      DeviceBottomPadding(),
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
    final options = ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes'];

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

  void _showCarModelBottomSheet(ThemeManager themeManager) {
    final options = ['Camry', 'Accord', 'Focus', 'X5', 'C-Class'];

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

  void _showCarYearBottomSheet(ThemeManager themeManager) {
    final options = ['2024', '2023', '2022', '2021', '2020', '2019'];

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
    AppLogger.log('\n========== STARTING VEHICLE REGISTRATION FLOW ==========');

    if (selectedCarName == null ||
        selectedCarModel == null ||
        selectedCarYear == null ||
        selectedSeats == null ||
        licensePlateController.text.isEmpty ||
        colorController.text.isEmpty ||
        selectedAC == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please fill all car information fields',
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication token not found. Please login again.',
        );
        return;
      }

      context.pushNamed(
        'kycVerification',
        extra: {
          'token': token,
          'carMake': selectedCarName!,
          'carModel': selectedCarModel!,
          'carYear': selectedCarYear!,
          'carSeats': selectedSeats!,
          'licenseNumber': licenseNumberController.text,
          'licensePlate': licensePlateController.text,
          'carColor': colorController.text,
          'isAcEnabled': selectedAC == 'Yes',
        },
      );
    } catch (e) {
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }
}
