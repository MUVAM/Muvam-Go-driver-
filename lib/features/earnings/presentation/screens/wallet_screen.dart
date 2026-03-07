import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/features/earnings/data/provider/wallet_provider.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/transaction_item.dart';
import 'package:muvam_rider/features/earnings/presentation/widgets/wallet_card_widget.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/images.dart';

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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                    MuvamTexts.bodyLarge16(
                      context,
                      text: 'Failed to load wallet data',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kBlackColor,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => walletProvider.fetchWalletSummary(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kMainColor,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MuvamTexts.headlineSmall24(
                        context,
                        text: 'Wallet',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.pushNamed(AppRoutes.howToWithdraw.name),
                        child: MuvamTexts.bodyLarge16(
                          context,
                          text: 'How to withdraw?',
                          isTextWidget: true,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kMainColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  WalletCardWidget(
                    walletSummary: walletSummary,
                    walletProvider: walletProvider,
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
                                ? AppColors.kMainColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Center(
                            child: MuvamTexts.bodyMedium14(
                              context,
                              text: tab,
                              isTextWidget: true,
                              fontWeight: FontWeight.w500,
                              color: selectedTab == index
                                  ? AppColors.kWhiteColor
                                  : AppColors.kBlackColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 15.h),
                  MuvamTexts.headlineMedium28(
                    context,
                    text: walletProvider.formatAmount(
                      walletSummary.totalEarnings,
                    ),
                    isTextWidget: true,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MuvamTexts.titleMedium18(
                        context,
                        text: 'Transaction history',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                      Container(
                        width: 120.w,
                        height: 24.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.kGreyColor.withValues(alpha: 0.5),
                            width: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.kWhiteColor,
                            value: selectedFilter,
                            icon: Padding(
                              padding: EdgeInsets.only(left: 6.w),
                              child: SvgPicture.asset(ConstImages.dropDown),
                            ),
                            isExpanded: false,
                            isDense: true,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.kBlackColor,
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
                                SizedBox(height: 8.h),
                                MuvamTexts.bodyLarge16(
                                  context,
                                  text: 'No transactions yet',
                                  isTextWidget: true,
                                  color: AppColors.kGreyColor,
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
