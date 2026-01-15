import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/earnings/presentation/screens/bank_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/earnings/data/provider/withdrawal_provider.dart';

class BankSelectorWidget extends StatelessWidget {
  final BuildContext parentContext;

  const BankSelectorWidget({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final provider = Provider.of<WithdrawalProvider>(context);

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
                    parentContext,
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
              color: const Color(ConstColors.fieldColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: provider.isLoading
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              color: themeManager.getTextColor(context),
                              strokeWidth: 2,
                            ),
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
                SvgPicture.asset(
                  ConstImages.dropDownIcon,
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.scaleDown,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
