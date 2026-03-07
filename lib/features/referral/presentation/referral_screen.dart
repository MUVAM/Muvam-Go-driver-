import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_routes.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';
import 'package:muvam_rider/features/referral/data/providers/referral_provider.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() async {
    final referralProvider = context.read<ReferralProvider>();

    final hasData = referralProvider.referralData != null;

    if (hasData && !_hasLoadedOnce) {
      setState(() {
        _hasLoadedOnce = true;
      });
      referralProvider.fetchReferralCode();
    } else if (!hasData) {
      await referralProvider.fetchReferralCode();

      if (mounted) {
        setState(() {
          _hasLoadedOnce = true;
        });
      }
    } else {
      referralProvider.fetchReferralCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kMainColor,
      body: SafeArea(
        child: Consumer<ReferralProvider>(
          builder: (context, referralProvider, child) {
            final shouldShowLoader =
                !_hasLoadedOnce &&
                referralProvider.referralData == null &&
                referralProvider.isLoading;

            return shouldShowLoader
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.kWhiteColor,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
                    child: Column(
                      children: [
                        SizedBox(height: AppSpacings.k20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 35.w,
                              height: 35.h,
                              decoration: BoxDecoration(
                                color: AppColors.kWhiteColor,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              padding: EdgeInsets.all(5.w),
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: SvgPicture.asset(
                                  ConstImages.arrowLeftAlt,
                                  fit: BoxFit.contain,
                                  color: AppColors.kBlackColor,
                                ),
                              ),
                            ),
                            MuvamTexts.headlineSmall24(
                              context,
                              text: 'Referral',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWhiteColor,
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pushNamed(AppRoutes.referralRules.name);
                              },
                              child: MuvamTexts.bodyLarge16(
                                context,
                                text: 'Rules',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kWhiteColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                        MuvamTexts.headlineSmall24(
                          context,
                          text: 'Invite new users and \nget a free ride',
                          isTextWidget: true,
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          height: 1,
                          color: AppColors.kWhiteColor,
                          center: true,
                        ),
                        SizedBox(height: 20.h),
                        MuvamTexts.bodyLarge16(
                          context,
                          text:
                              'Refer up to 10 friends and as soon as they \nplace a ride order, you get free ride for a nweek',
                          isTextWidget: true,
                          fontWeight: FontWeight.w400,
                          color: AppColors.kWhiteColor,
                          center: true,
                        ),
                        SizedBox(height: 24.h),
                        if (referralProvider.errorMessage != null &&
                            referralProvider.referralData == null)
                          Container(
                            width: 350.w,
                            height: 157.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MuvamTexts.bodyMedium14(
                                    context,
                                    text: 'Failed to load referral code',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.kWhiteColor,
                                    center: true,
                                  ),
                                  SizedBox(height: 5.h),
                                  GestureDetector(
                                    onTap: () {
                                      referralProvider.fetchReferralCode();
                                    },
                                    child: MuvamTexts.bodyMedium14(
                                      context,
                                      text: 'Tap to retry',
                                      isTextWidget: true,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kWhiteColor,
                                      textDecoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 350.w,
                            height: 157.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MuvamTexts.bodyMedium14(
                                  context,
                                  text: 'Invitation code',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.kWhiteColor,
                                  center: true,
                                ),
                                SizedBox(height: 15.h),
                                Container(
                                  width: 320.w,
                                  height: 1.h,
                                  color: AppColors.kWhiteColor,
                                ),
                                SizedBox(height: 15.h),
                                GestureDetector(
                                  onLongPress: () {
                                    _copyToClipboard(
                                      context,
                                      referralProvider.referralData?.code ?? '',
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      MuvamTexts.headlineSmall24(
                                        context,
                                        text:
                                            referralProvider
                                                .referralData
                                                ?.code ??
                                            'N/A',
                                        isTextWidget: true,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 35,
                                        color: AppColors.kWhiteColor,
                                      ),
                                      SizedBox(width: 10.w),
                                      GestureDetector(
                                        onTap: () {
                                          _copyToClipboard(
                                            context,
                                            referralProvider
                                                    .referralData
                                                    ?.code ??
                                                '',
                                          );
                                        },
                                        child: Icon(
                                          Icons.copy,
                                          color: AppColors.kWhiteColor,
                                          size: 24.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15.h),
                                MuvamTexts.bodyMedium14(
                                  context,
                                  text:
                                      'You are one step ahead of your friends',
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.kWhiteColor,
                                  center: true,
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 20.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: 10.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              MuvamTexts.bodyLarge16(
                                context,
                                text: 'Total Invites',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kWhiteColor,
                              ),
                              SizedBox(height: 10.h),
                              MuvamTexts.headlineSmall24(
                                context,
                                text:
                                    '${referralProvider.referralData?.totalUses ?? 0}',
                                isTextWidget: true,
                                fontSize: 80,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kWhiteColor,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (referralProvider.referralData != null) {
                              referralProvider.shareReferralCode();
                            }
                          },
                          child: Container(
                            width: 353.w,
                            height: 47.h,
                            decoration: BoxDecoration(
                              color: AppColors.kWhiteColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: MuvamTexts.button16(
                                context,
                                text: 'Share link',
                                isTextWidget: true,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kMainColor,
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

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    CustomFlushbar.showSuccess(
      context: context,
      message: 'Referral code copied to clipboard',
    );
  }
}
