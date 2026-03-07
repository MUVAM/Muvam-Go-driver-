import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/features/auth/data/provider/auth_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String countryCode = '+234';
  String countryFlag = '🇳🇬';
  final TextEditingController phoneController = TextEditingController();

  bool _isValidPhone() {
    String phone = phoneController.text.trim();
    return phone.length == 10 || (phone.length == 11 && phone.startsWith('0'));
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
  }

  void _showCustomCountryPicker(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<Country> allCountries = CountryService().getAll();
    List<Country> filteredCountries = allCountries;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: AppColors.kWhiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 50.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          height: 1.0,
                        ),
                        suffixIcon: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Image.asset(
                            'assets/images/search.png',
                            width: 20.w,
                            height: 20.h,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            filteredCountries = allCountries;
                          } else {
                            filteredCountries = allCountries
                                .where(
                                  (country) =>
                                      country.name.toLowerCase().contains(
                                        value.toLowerCase(),
                                      ) ||
                                      country.phoneCode.contains(value),
                                )
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: filteredCountries.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected =
                            countryCode == '+${country.phoneCode}';

                        return InkWell(
                          onTap: () {
                            setState(() {
                              countryCode = '+${country.phoneCode}';
                              countryFlag = country.flagEmoji;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              children: [
                                Text(
                                  country.flagEmoji,
                                  style: TextStyle(fontSize: 28.sp),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.kBlackColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${country.phoneCode}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isSelected) ...[
                                  SizedBox(width: 12.w),
                                  const Icon(
                                    Icons.check,
                                    color: AppColors.kMainColor,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Flexible(
              flex: 15,
              child: Image.asset(ConstImages.onboardCar, fit: BoxFit.contain),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  const Spacer(),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Enter your phone number',
                    fontWeight: FontWeight.w700,
                    color: AppColors.kBlackColor,
                    isTextWidget: true,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            MuvamTexts.bodyMedium14(
              context,
              text: 'We will send you a validation code',
              color: AppColors.kSubtitleColor,
              isTextWidget: true,
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                width: double.infinity,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showCustomCountryPicker(context);
                      },
                      child: Container(
                        width: 100.w,
                        height: 42.h,
                        margin: EdgeInsets.only(left: 4.w),
                        decoration: BoxDecoration(
                          color: AppColors.kWhiteColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              countryFlag,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            SizedBox(width: 2.w),
                            Flexible(
                              child: MuvamTexts.bodyMedium14(
                                context,
                                text: countryCode,
                                isTextWidget: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            SvgPicture.asset(
                              ConstImages.dropDown,
                              fit: BoxFit.scaleDown,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kBlackColor,
                        ),
                        maxLength: 11,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 0,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return GestureDetector(
                    onTap: _isValidPhone() && !authProvider.isLoading
                        ? () async {
                            String phoneNumber = phoneController.text.trim();

                            if (phoneNumber.startsWith('0')) {
                              phoneNumber = phoneNumber.substring(1);
                            }
                            final fullPhone = countryCode + phoneNumber;
                            final success = await authProvider.sendOtp(
                              fullPhone,
                            );
                            if (!mounted) return;

                            if (success) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('user_phone', fullPhone);

                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );

                              if (mounted) {
                                context.pushNamedRoute(
                                  AppRoutes.otp.name,
                                  extra: {'phoneNumber': fullPhone},
                                );
                              }
                            } else {
                              CustomFlushbar.showError(
                                context: context,
                                message:
                                    authProvider.errorMessage ??
                                    'Failed to send OTP',
                              );
                            }
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: _isValidPhone() && !authProvider.isLoading
                            ? AppColors.kMainColor
                            : AppColors.kFieldColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: authProvider.isLoading
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
                                text: 'Continue',
                                color: AppColors.kWhiteColor,
                                fontWeight: FontWeight.w600,
                                isTextWidget: true,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            DeviceBottomPadding(),
          ],
        ),
      ),
    );
  }
}
