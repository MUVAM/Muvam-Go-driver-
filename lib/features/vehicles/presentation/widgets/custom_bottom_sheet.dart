import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

class CustomBottomSheet {
  static void showSelectionBottomSheet({
    required BuildContext context,
    required ThemeManager themeManager,
    required String title,
    required List<String> options,
    required Function(String) onSelected,
    String? selectedValue,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeManager.getBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MuvamTexts.titleMedium18(
                context,
                text: title,
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: themeManager.getTextColor(context),
              ),
              SizedBox(height: 10.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: options.map((option) {
                      bool isSelected = selectedValue == option;
                      return Column(
                        children: [
                          ListTile(
                            title: MuvamTexts.bodyLarge16(
                              context,
                              text: option,
                              isTextWidget: true,
                              color: themeManager.getTextColor(context),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check, color: AppColors.kMainColor)
                                : null,
                            onTap: () {
                              onSelected(option);
                              context.pop();
                            },
                          ),
                          if (option != options.last) const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
