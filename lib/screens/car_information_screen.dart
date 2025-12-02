import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/theme_manager.dart';
import 'home_screen.dart';

class CarInformationScreen extends StatefulWidget {
  const CarInformationScreen({super.key});

  @override
  State<CarInformationScreen> createState() => _CarInformationScreenState();
}

class _CarInformationScreenState extends State<CarInformationScreen> {
  final TextEditingController carNameController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();
  final TextEditingController carYearController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController carColorController = TextEditingController();
  final TextEditingController acController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: themeManager.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeManager.getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Text(
                  'Car Information',
                  style: ConstTextStyles.createAccountTitle.copyWith(
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your car details correctly.',
                  style: ConstTextStyles.createAccountSubtitle.copyWith(
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 30.h),
                _buildTextField('Car Name', carNameController, ConstColors.formFieldColor, hasDropdown: true),
                SizedBox(height: 20.h),
                _buildTextField('Car Model', carModelController, ConstColors.formFieldColor, hasDropdown: true),
                SizedBox(height: 20.h),
                _buildTextField('Car Year', carYearController, ConstColors.formFieldColor, hasDropdown: true),
                SizedBox(height: 20.h),
                _buildTextField('License Plate', licensePlateController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Car Color', carColorController, ConstColors.formFieldColor, hasDropdown: true),
                SizedBox(height: 20.h),
                _buildTextField('AC', acController, ConstColors.formFieldColor, hasDropdown: true),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  child: Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
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

  Widget _buildTextField(String label, TextEditingController controller, int backgroundColor, {bool hasDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            height: 1.0,
            color: Colors.black,
          ),
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
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  ),
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
}