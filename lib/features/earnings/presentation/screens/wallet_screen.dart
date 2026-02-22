import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/transaction_item.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/wallet_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/how_to_withdraw.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  int selectedTab = 0;
  final List<String> tabs = ['Weekly', 'Monthly', 'All'];

  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Tip',
    'Commission',
    'Ride Earning',
    'Withdrawal',
  ];

  // Maps display label → backend type value
  final Map<String, String> filterTypeMap = {
    'All': 'all',
    'Tip': 'tip',
    'Commission': 'commission',
    'Ride Earning': 'ride_earning',
    'Withdrawal': 'withdrawal',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWalletSummary();
    });
  }

  bool _isInCurrentWeek(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final end = start.add(const Duration(days: 7));
      return dt.isAfter(start) && dt.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  bool _isInCurrentMonth(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month;
    } catch (_) {
      return false;
    }
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
              return const Center(child: CircularProgressIndicator.adaptive());
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
                      child: const Text('Retry'),
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                  SizedBox(height: 30.h),
                  WalletCardWidget(
                    walletSummary: walletSummary,
                    themeManager: themeManager,
                    walletProvider: walletProvider,
                    context: context,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      return GestureDetector(
                        onTap: () => setState(() => selectedTab = index),
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
                        width: 120.w,
                        height: 24.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: themeManager
                                .getSecondaryTextColor(context)
                                .withValues(alpha: 0.5),
                            width: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Colors.white,
                            value: selectedFilter,
                            icon: Padding(
                              padding: EdgeInsets.only(left: 6.w),
                              child: SvgPicture.asset(ConstImages.dropDown),
                            ),
                            isExpanded: false,
                            isDense: true,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: themeManager.getTextColor(context),
                            ),
                            items: filterOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() => selectedFilter = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final typeFilter =
                            filterTypeMap[selectedFilter] ?? 'all';

                        final filteredTransactions = walletSummary.transactions
                            .where((t) {
                              if (selectedTab == 0 &&
                                  !_isInCurrentWeek(t.createdAt))
                                return false;
                              if (selectedTab == 1 &&
                                  !_isInCurrentMonth(t.createdAt))
                                return false;

                              if (typeFilter != 'all' && t.type != typeFilter)
                                return false;

                              return true;
                            })
                            .toList();

                        if (filteredTransactions.isEmpty) {
                          return Center(
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
                          );
                        }

                        return ListView.separated(
                          itemCount: filteredTransactions.length,
                          separatorBuilder: (context, index) => Divider(
                            thickness: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return TransactionItem(
                              description: transaction.description,
                              dateTime: walletProvider.formatDateTime(
                                transaction.createdAt,
                              ),
                              formattedAmount: walletProvider.formatAmount(
                                transaction.amount,
                              ),
                              type: transaction.type,
                            );
                          },
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
}
