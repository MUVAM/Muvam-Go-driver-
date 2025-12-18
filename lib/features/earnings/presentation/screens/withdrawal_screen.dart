import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';
import 'bank_selection_screen.dart';
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdrawal() async {
    final provider = Provider.of<WithdrawalProvider>(context, listen: false);

    if (provider.selectedBank == null) {
      _showErrorDialog('Please select a bank');
      return;
    }

    if (_accountNumberController.text.trim().isEmpty) {
      _showErrorDialog('Please enter account number');
      return;
    }

    if (_accountNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter account name');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      _showErrorDialog('Please enter amount');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
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
      _showErrorDialog(provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: 10.w,
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
            top: 85.h,
            left: 20.w,
            right: 20.w,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Withdrawal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 24.sp,
                        color: themeManager.getTextColor(context),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Please enter your correct bank details',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        color: themeManager.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  _buildBankSelector(themeManager, withdrawalProvider),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    'Account Number',
                    _accountNumberController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField('Account Name', _accountNameController),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    'Amount',
                    _amountController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 40.h),
                  GestureDetector(
                    onTap: withdrawalProvider.isWithdrawing
                        ? null
                        : _handleWithdrawal,
                    child: Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: withdrawalProvider.isWithdrawing
                            ? Colors.grey
                            : Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: withdrawalProvider.isWithdrawing
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
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
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector(
    ThemeManager themeManager,
    WithdrawalProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank name',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
            color: themeManager.getTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: provider.isLoading
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BankSelectionScreen(),
                    ),
                  );
                },
          child: Container(
            width: double.infinity,
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            decoration: BoxDecoration(
              color: Color(ConstColors.fieldColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: provider.isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: themeManager.getTextColor(context),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          provider.selectedBank?.name ?? 'Select your bank',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: provider.selectedBank != null
                                ? 14.sp
                                : 12.sp,
                            color: provider.selectedBank != null
                                ? themeManager.getTextColor(context)
                                : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: themeManager.getTextColor(context),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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
          width: double.infinity,
          height: 45.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.fieldColor).withOpacity(0.12),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
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
