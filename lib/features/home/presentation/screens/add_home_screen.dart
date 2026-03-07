import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';

class AddHomeScreen extends StatefulWidget {
  const AddHomeScreen({super.key});

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final List<String> recentLocations = [
    'Nsukka, Ogige',
    'Holy ghost Enugu',
    'Abakpa, Enugu',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: MuvamTexts.headlineSmall24(
                context,
                text: 'Add home',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlackColor,
              ),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search an address',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kGreyColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20.sp,
                      color: AppColors.kGreyColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: MuvamTexts.bodyMedium14(
                context,
                text: 'Recent locations',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
                color: AppColors.kRecentLocationColor,
              ),
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: ListView.separated(
                itemCount: recentLocations.length,
                separatorBuilder: (context, index) =>
                    Divider(thickness: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: MuvamTexts.bodyMedium14(
                      context,
                      text: recentLocations[index],
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kBlackColor,
                    ),
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
