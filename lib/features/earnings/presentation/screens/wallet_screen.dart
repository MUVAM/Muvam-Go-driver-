import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/transaction_item.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/how_to_withdraw.dart';
import 'withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  int selectedTab = 0;
  final List<String> tabs = ['Weekly', 'Monthly', 'All'];

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HowToWithdraw()),
                    ),
                    child: Text(
                      'How to withdraw',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Color(ConstColors.mainColor),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Wallet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 20.h),
              Stack(
                children: [
                  Container(
                    width: 353.w,
                    height: 147.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(15.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your balance',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  letterSpacing: -0.32,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                width: 100.w,
                                height: 30.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WithdrawalScreen(),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Withdraw',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Color(ConstColors.mainColor),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₦1,000',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Pending balance',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              letterSpacing: -0.32,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '₦1,000',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              letterSpacing: -0.32,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -54.h,
                    left: -43.w,
                    child: Container(
                      width: 103.w,
                      height: 103.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 99.h,
                    left: 237.w,
                    child: Container(
                      width: 79.w,
                      height: 79.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 89.h,
                    left: 297.w,
                    child: Container(
                      width: 79.w,
                      height: 79.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: tabs.asMap().entries.map((entry) {
                  int index = entry.key;
                  String tab = entry.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                    child: Container(
                      width: 75.w,
                      height: 25.h,
                      margin: EdgeInsets.only(right: 10.w),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: selectedTab == index
                            ? Color(ConstColors.mainColor)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: selectedTab == index
                                ? Colors.white
                                : themeManager.getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 15.h),
              Text(
                '₦15,000',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                  height: 1.0,
                  letterSpacing: -0.41,
                  color: themeManager.getTextColor(context),
                ),
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  Container(
                    width: 100.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeManager.getSecondaryTextColor(context),
                        width: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: themeManager.getTextColor(context),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16.sp,
                          color: themeManager.getTextColor(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      Divider(thickness: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final transactions = [
                      {
                        'amount': 'Withdrawal',
                        'dateTime': 'Dec 15, 2024 • 2:30 PM',
                        'status': '-₦500',
                        'color': Colors.black,
                      },
                      {
                        'amount': 'Credit',
                        'dateTime': 'Dec 14, 2024 • 10:15 AM',
                        'status': '+₦1,200',
                        'color': Colors.black,
                      },
                      {
                        'amount': 'Withdrawal',
                        'dateTime': 'Dec 13, 2024 • 6:45 PM',
                        'status': '-₦1,200',
                        'color': Colors.black,
                      },
                      {
                        'amount': 'Credit',
                        'dateTime': 'Dec 12, 2024 • 1:20 PM',
                        'status': '+₦1,200',
                        'color': Colors.black,
                      },
                    ];
                    final transaction = transactions[index];
                    return TransactionItem(
                      amount: transaction['amount'] as String,
                      dateTime: transaction['dateTime'] as String,
                      status: transaction['status'] as String,
                      statusColor: transaction['color'] as Color,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFundWalletSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: themeManager.getCardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fund wallet',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'How much do you want to add?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    width: 353.w,
                    height: 39.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.4,
                      ),
                    ),
                    padding: EdgeInsets.all(10.w),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        prefixText: '₦ ',
                        prefixStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: themeManager.getTextColor(context),
                        ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: themeManager.getTextColor(context),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Container(
                    width: 353.w,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
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
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
