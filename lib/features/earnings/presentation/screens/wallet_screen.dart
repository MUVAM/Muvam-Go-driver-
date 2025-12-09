import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            if (walletProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(ConstColors.mainColor),
                ),
              );
            }

            final walletSummary = walletProvider.walletSummary;

            if (walletSummary == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load wallet data',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: themeManager.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => walletProvider.fetchWalletSummary(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(ConstColors.mainColor),
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
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
                          MaterialPageRoute(
                            builder: (context) => HowToWithdraw(),
                          ),
                        ),
                        child: Text(
                          'How to withdraw?',
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
                  _buildWalletCard(walletSummary, themeManager, walletProvider),
                  SizedBox(height: 20.h),
                  // Static Tabs (UI only - not functional)
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
                    walletProvider.formatAmount(walletSummary.totalEarnings),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                      height: 1.0,
                      letterSpacing: -0.41,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction history',
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
                            SizedBox(width: 6.w),
                            SvgPicture.asset(ConstImages.dropDown),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: walletSummary.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48.sp,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: walletSummary.transactions.length,
                            separatorBuilder: (context, index) => Divider(
                              thickness: 1,
                              color: Colors.grey.shade300,
                            ),
                            itemBuilder: (context, index) {
                              final transaction =
                                  walletSummary.transactions[index];
                              final isCredit = transaction.type == 'credit';
                              return TransactionItem(
                                amount: transaction.description,
                                dateTime: walletProvider.formatDateTime(
                                  transaction.createdAt,
                                ),
                                status:
                                    '${isCredit ? '+' : '-'}${walletProvider.formatAmount(transaction.amount)}',
                                statusColor: themeManager.getTextColor(context),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    walletSummary,
    ThemeManager themeManager,
    WalletProvider walletProvider,
  ) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 150.h,
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Color(ConstColors.blackColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    walletProvider.formatAmount(walletSummary.balance),
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
                Spacer(),
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
                  walletProvider.formatAmount(walletSummary.pendingBalance),
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
    );
  }
}
