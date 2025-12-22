import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/editable_field.dart';

class EditFullNameScreen extends StatefulWidget {
  const EditFullNameScreen({super.key});

  @override
  EditFullNameScreenState createState() => EditFullNameScreenState();
}

class EditFullNameScreenState extends State<EditFullNameScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  bool isFirstNameEditable = false;
  bool isLastNameEditable = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final fullName = profileProvider.userName;

    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    if (firstNameController.text.isEmpty) {
      firstNameController.text = firstName;
    }
    if (lastNameController.text.isEmpty) {
      lastNameController.text = lastName;
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    Provider.of<ProfileProvider>(context, listen: false);

    '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
        .trim();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    onTap: _saveName,
                    child: Container(
                      width: 60.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
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
              SizedBox(height: 20.h),
              Text(
                'Full name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30.h),
              EditableField(
                label: 'First name',
                controller: firstNameController,
                isEditable: isFirstNameEditable,
                onEditTap: () =>
                    setState(() => isFirstNameEditable = !isFirstNameEditable),
              ),
              SizedBox(height: 20.h),
              EditableField(
                label: 'Last name',
                controller: lastNameController,
                isEditable: isLastNameEditable,
                onEditTap: () =>
                    setState(() => isLastNameEditable = !isLastNameEditable),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
