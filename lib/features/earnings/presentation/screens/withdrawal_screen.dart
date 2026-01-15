import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/bank_selector_widget.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/text_field_widget.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'withdrawal_success_screen.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  WithdrawalScreenState createState() => WithdrawalScreenState();
}

class WithdrawalScreenState extends State<WithdrawalScreen> {
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WithdrawalProvider>(context, listen: false);
      if (provider.banks.isEmpty) {
        provider.fetchBanks();
      }
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdrawal() async {
    final provider = Provider.of<WithdrawalProvider>(context, listen: false);

    if (provider.selectedBank == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select a bank',
      );
      return;
    }

    if (_accountNumberController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter account number',
      );
      return;
    }

    if (_accountNameController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter account name',
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter amount',
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter a valid amount',
      );
      return;
    }

    final success = await provider.withdraw(
      accountName: _accountNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      amount: amount,
    );

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawalSuccessScreen(amount: amount),
        ),
      );
    } else if (provider.errorMessage != null) {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 30.h),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        ConstImages.back,
                        width: 30.w,
                        height: 30.h,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  'Withdrawal',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 26.sp,
                    color: themeManager.getTextColor(context),
                  ),
                ),
                Text(
                  'Please enter your correct bank details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  BankSelectorWidget(parentContext: context),
                  SizedBox(height: 24.h),
                  TextFieldWidget(
                    label: 'Account number',
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    hintText: '1234567890',
                  ),
                  SizedBox(height: 24.h),
                  TextFieldWidget(
                    label: 'Account name',
                    controller: _accountNameController,
                    hintText: 'John Doe',
                  ),
                  SizedBox(height: 24.h),
                  TextFieldWidget(
                    label: 'Amount',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    hintText: '#',
                  ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
            decoration: BoxDecoration(
              color: themeManager.getBackgroundColor(context),
            ),
            child: GestureDetector(
              onTap: withdrawalProvider.isWithdrawing
                  ? null
                  : _handleWithdrawal,
              child: Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: withdrawalProvider.isWithdrawing
                      ? Color(ConstColors.mainColor)
                      : Color(0xFFB1B1B1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: withdrawalProvider.isWithdrawing
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Withdraw',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 17.sp,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
