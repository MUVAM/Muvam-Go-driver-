import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'withdrawal_success_screen.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  WithdrawalScreenState createState() => WithdrawalScreenState();
}

class WithdrawalScreenState extends State<WithdrawalScreen> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: 70.h,
            left: 20.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: themeManager.getCardColor(context),
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: themeManager.getTextColor(context),
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Positioned(
            top: 140.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 24.sp,
                    color: themeManager.getTextColor(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your correct bank details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 16.sp,
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 40.h),
                _buildTextField('Bank Name', _bankNameController),
                SizedBox(height: 20.h),
                _buildTextField('Account Number', _accountNumberController),
                SizedBox(height: 20.h),
                _buildTextField('Amount', _amountController),
                SizedBox(height: 20.h),
                _buildTextField('Account Name', _accountNameController),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WithdrawalSuccessScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Withdraw',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            color: themeManager.getTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 45.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.fieldColor).withOpacity(0.12),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              color: themeManager.getTextColor(context),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(15.w),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
