import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/auth/data/provider/%20delete_account_provider.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/reason_item.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int? selectedReason;

  final List<String> reasons = [
    'I am no longer using my account',
    'It is not available in my state',
    'I want to change my phone number',
    'It is too expensive',
    'I just bought a car',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<DeleteAccountProvider>(
          builder: (context, deleteProvider, child) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacings.k20),
                  Row(
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
                      MuvamTexts.titleMedium18(
                        context,
                        text: 'Delete Account',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlackColor,
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text:
                        'We\'re really sorry to see you go. Are you sure you want to delete your account? Once you confirm, your data will be gone.',
                    isTextWidget: true,
                    color: AppColors.kBlackColor,
                    height: 1.3,
                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reasons.length,
                      itemBuilder: (context, index) {
                        return ReasonItem(
                          reason: reasons[index],
                          isSelected: selectedReason == index,
                          onTap: () => setState(() => selectedReason = index),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: deleteProvider.isDeleting
                          ? AppColors.kGreyColor
                          : AppColors.kError,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: deleteProvider.isDeleting
                            ? null
                            : () {
                                if (selectedReason == null) {
                                  CustomFlushbar.showInfo(
                                    context: context,
                                    message: 'Please select a reason',
                                  );
                                  return;
                                }
                                _showDeleteConfirmationSheet(context);
                              },
                        child: Center(
                          child: deleteProvider.isDeleting
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    color: AppColors.kWhiteColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : MuvamTexts.button16(
                                  context,
                                  text: 'Delete my account',
                                  color: AppColors.kWhiteColor,
                                  fontWeight: FontWeight.w600,
                                  isTextWidget: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                  DeviceBottomPadding(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            MuvamTexts.titleMedium18(
              context,
              text: 'Delete Account',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
            SizedBox(height: 20.h),
            MuvamTexts.bodyMedium14(
              context,
              text:
                  'Are you sure you want to delete your account? This action cannot be undone.',
              isTextWidget: true,
              center: true,
              color: AppColors.kBlackColor,
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: AppColors.kGreyColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () => Navigator.pop(context),
                        child: Center(
                          child: MuvamTexts.button16(
                            context,
                            text: 'Cancel',
                            color: AppColors.kWhiteColor,
                            fontWeight: FontWeight.w600,
                            isTextWidget: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Container(
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: AppColors.kError,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () async {
                          context.pop();
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          if (mounted) {
                            _deleteAccount();
                          }
                        },
                        child: Center(
                          child: MuvamTexts.button16(
                            context,
                            text: 'Delete account',
                            color: AppColors.kWhiteColor,
                            fontWeight: FontWeight.w600,
                            isTextWidget: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final deleteProvider = context.read<DeleteAccountProvider>();
    final reason = reasons[selectedReason!];

    final success = await deleteProvider.deleteAccount(reason);

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message:
            deleteProvider.successMessage ?? 'Account deleted successfully',
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      context.goNamedRoute(AppRoutes.onboarding.name);
    } else {
      CustomFlushbar.showError(
        context: context,
        message: deleteProvider.errorMessage ?? 'Failed to delete account',
      );
    }
  }
}
