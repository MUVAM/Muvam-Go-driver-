import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/edit_full_name_text_field.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController emailController;
  late TextEditingController stateController;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    fullNameController = TextEditingController(text: profileProvider.userName);
    phoneController = TextEditingController(text: profileProvider.userPhone);
    dobController = TextEditingController(
      text: profileProvider.userDateOfBirth,
    );
    emailController = TextEditingController(text: profileProvider.userEmail);
    stateController = TextEditingController(text: profileProvider.userCity);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime(2000);
    if (dobController.text.isNotEmpty) {
      try {
        final parts = dobController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } catch (e) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.kMainColor,
              onPrimary: AppColors.kWhiteColor,
              onSurface: AppColors.kBlackColor,
              surface: AppColors.kWhiteColor,
            ),
            dialogBackgroundColor: AppColors.kWhiteColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String month = picked.month.toString().padLeft(2, '0');
      String day = picked.day.toString().padLeft(2, '0');
      dobController.text = "$month/$day/${picked.year}";
    }
  }

  Future<void> _saveProfile() async {
    if (fullNameController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter full name',
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter email address',
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter a valid email address',
      );
      return;
    }

    final provider = context.read<ProfileProvider>();

    final nameParts = fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await provider.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      email: emailController.text.trim(),
      dateOfBirth: dobController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Profile updated successfully',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed(AppRoutes.home.name);
        }
      });
    } else {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage ?? 'Failed to update profile',
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    emailController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: AppColors.kFormFieldColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.kBlackColor,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: MuvamTexts.titleMedium18(
                            context,
                            text: 'Edit profile',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditFullNameTextField(
                          label: 'Full name',
                          controller: fullNameController,
                        ),
                        SizedBox(height: 16.h),
                        EditFullNameTextField(
                          label: 'Phone number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: true,
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: EditFullNameTextField(
                              label: 'Date of birth',
                              controller: dobController,
                              hintText: 'MM/DD/YYYY',
                              readOnly: true,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        EditFullNameTextField(
                          label: 'Email address',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16.h),
                        EditFullNameTextField(
                          label: 'State',
                          controller: stateController,
                          readOnly: true,
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20.w),
                  child: GestureDetector(
                    onTap: provider.isUpdating ? null : _saveProfile,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: provider.isUpdating
                            ? AppColors.kGreyColor
                            : AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: provider.isUpdating
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: const CircularProgressIndicator(
                                  color: AppColors.kWhiteColor,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : MuvamTexts.button16(
                                context,
                                text: 'Save changes',
                                isTextWidget: true,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kWhiteColor,
                              ),
                      ),
                    ),
                  ),
                ),
                DeviceBottomPadding(),
              ],
            );
          },
        ),
      ),
    );
  }
}
