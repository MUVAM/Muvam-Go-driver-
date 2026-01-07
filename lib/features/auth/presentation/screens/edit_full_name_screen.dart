import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/edit_full_name_text_field.dart';
import 'package:muvam_rider/features/home/presentation/screens/home_screen.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class EditFullNameScreen extends StatefulWidget {
  const EditFullNameScreen({super.key});

  @override
  EditFullNameScreenState createState() => EditFullNameScreenState();
}

class EditFullNameScreenState extends State<EditFullNameScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController dobController;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    final fullName = profileProvider.userName;
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    emailController = TextEditingController(text: profileProvider.userEmail);
    dobController = TextEditingController(
      text: profileProvider.userDateOfBirth,
    );
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
      } catch (e) {
        AppLogger.log('Error parsing date: $e');
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(ConstColors.mainColor),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String month = picked.month.toString().padLeft(2, '0');
      String day = picked.day.toString().padLeft(2, '0');
      dobController.text = "$month/$day/${picked.year}";
      AppLogger.log('Date selected: ${dobController.text}');
    }
  }

  Future<void> _saveProfile() async {
    if (firstNameController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter first name',
      );
      return;
    }

    if (lastNameController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter last name',
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

    final success = await provider.updateUserProfile(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
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
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          ConstImages.back,
                          width: 30.w,
                          height: 30.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: provider.isUpdating ? null : _saveProfile,
                        child: Container(
                          width: 60.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: provider.isUpdating
                                ? Colors.grey
                                : Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: provider.isUpdating
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        EditFullNameTextField(
                          label: 'First name',
                          controller: firstNameController,
                        ),
                        SizedBox(height: 20.h),
                        EditFullNameTextField(
                          label: 'Last name',
                          controller: lastNameController,
                        ),
                        SizedBox(height: 20.h),
                        EditFullNameTextField(
                          label: 'Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20.h),
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
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
