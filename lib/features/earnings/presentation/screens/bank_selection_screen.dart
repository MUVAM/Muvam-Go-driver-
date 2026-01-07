import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/data/models/bank.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';

class BankSelectionScreen extends StatefulWidget {
  const BankSelectionScreen({super.key});

  @override
  State<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends State<BankSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Bank> _filteredBanks = [];
  Map<String, List<Bank>> _groupedBanks = {};
  List<String> _groupHeaders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WithdrawalProvider>(context, listen: false);
      _initializeBanks(provider.banks);
    });
  }

  void _initializeBanks(List<Bank> banks) {
    _filteredBanks = List.from(banks);
    _groupBanks(_filteredBanks);
  }

  void _groupBanks(List<Bank> banks) {
    _groupedBanks.clear();
    _groupHeaders.clear();

    for (var bank in banks) {
      String header;
      if (bank.name.isEmpty) {
        header = '#';
      } else {
        final firstChar = bank.name[0].toUpperCase();
        // Check if first character is a digit
        if (RegExp(r'[0-9]').hasMatch(firstChar)) {
          header = '#';
        } else if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
          header = firstChar;
        } else {
          header = '#';
        }
      }

      if (!_groupedBanks.containsKey(header)) {
        _groupedBanks[header] = [];
        _groupHeaders.add(header);
      }
      _groupedBanks[header]!.add(bank);
    }

    _groupHeaders.sort((a, b) {
      if (a == '#') return -1;
      if (b == '#') return 1;
      return a.compareTo(b);
    });

    setState(() {});
  }

  void _filterBanks(String query) {
    final provider = Provider.of<WithdrawalProvider>(context, listen: false);

    if (query.isEmpty) {
      _filteredBanks = List.from(provider.banks);
    } else {
      _filteredBanks = provider.banks
          .where(
            (bank) => bank.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    _groupBanks(_filteredBanks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: themeManager.getCardColor(context),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: themeManager.getTextColor(context),
                        size: 20.sp,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Select Bank',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20.sp,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBanks,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    color: themeManager.getTextColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search bank',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: withdrawalProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(ConstColors.mainColor),
                      ),
                    )
                  : _filteredBanks.isEmpty
                  ? Center(
                      child: Text(
                        'No banks found',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          color: themeManager.getSecondaryTextColor(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _groupHeaders.length,
                      itemBuilder: (context, index) {
                        final header = _groupHeaders[index];
                        final banksInGroup = _groupedBanks[header] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 24.h,
                                bottom: 12.h,
                              ),
                              child: Text(
                                header,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  color: themeManager.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            ...banksInGroup.map((bank) {
                              return GestureDetector(
                                onTap: () {
                                  withdrawalProvider.selectBank(bank);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    bank.name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.sp,
                                      color: themeManager.getTextColor(context),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
