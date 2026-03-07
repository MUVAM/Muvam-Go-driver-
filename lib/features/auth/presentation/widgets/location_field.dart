import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String) onSelect;
  final List<String> suggestions;
  final bool showSuggestions;

  const LocationField({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onSelect,
    required this.suggestions,
    required this.showSuggestions,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: 'Location',
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.kLocationFieldColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: widget.controller,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 15.h,
              ),
            ),
            onChanged: widget.onSearch,
          ),
        ),
        if (widget.showSuggestions && widget.suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 5.h),
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_on,
                    size: 20.sp,
                    color: AppColors.kMainColor,
                  ),
                  title: MuvamTexts.bodyMedium14(
                    context,
                    text: suggestion,
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                  ),
                  onTap: () => widget.onSelect(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}
