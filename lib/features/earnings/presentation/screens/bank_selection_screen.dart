import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
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
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  const Spacer(),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Select Bank',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBanks,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search bank',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kGreyColor,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SvgPicture.asset(
                        ConstImages.search,
                        width: 20.w,
                        height: 20.h,
                        fit: BoxFit.scaleDown,
                        color: AppColors.kGreyColor,
                      ),
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
                        color: AppColors.kMainColor,
                      ),
                    )
                  : _filteredBanks.isEmpty
                  ? Center(
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: 'No banks found',
                        isTextWidget: true,
                        color: AppColors.kGreyColor,
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
                            if (index > 0) SizedBox(height: 24.h),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: MuvamTexts.bodyMedium14(
                                context,
                                text: header,
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kGreyColor,
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
                                  child: MuvamTexts.bodyLarge16(
                                    context,
                                    text: bank.name,
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.kBlackColor,
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
