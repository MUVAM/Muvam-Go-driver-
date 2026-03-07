import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/ratings/models/rating_model.dart';
import 'package:muvam_rider/features/ratings/presentation/widgets/rating_item.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<Rating> ratings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      int? userId;
      try {
        userId = prefs.getInt('user_id');
      } catch (e) {
        final userIdStr = prefs.getString('user_id');
        if (userIdStr != null) {
          userId = int.tryParse(userIdStr);
        }
      }

      if (token == null || userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await ApiService.getUserRatings(token, userId);

      if (response['success']) {
        final ratingResponse = RatingResponse.fromJson(response['data']);
        setState(() {
          ratings = ratingResponse.ratings;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return AppScaffold(
          backgroundColor: AppColors.kWhiteColor,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: MuvamTexts.titleMedium18(
                            context,
                            text: 'Ratings',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                profileProvider.userProfilePhoto.isNotEmpty
                    ? CircleAvatar(
                        radius: 40.r,
                        backgroundImage: NetworkImage(
                          profileProvider.userProfilePhoto,
                        ),
                      )
                    : Image.asset(
                        ConstImages.avatar,
                        width: 80.w,
                        height: 80.h,
                      ),
                MuvamTexts.titleMedium18(
                  context,
                  text: profileProvider.userName,
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlackColor,
                ),
                SizedBox(height: 5.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: EdgeInsets.only(right: index < 4 ? 5.w : 0),
                      child: Icon(
                        Icons.star,
                        size: 24.sp,
                        color: index < profileProvider.userRating
                            ? Colors.amber
                            : AppColors.kGreyColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MuvamTexts.titleMedium18(
                      context,
                      text: 'What your passengers said',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.kMainColor,
                          ),
                        )
                      : ratings.isEmpty
                      ? Center(
                          child: MuvamTexts.bodyLarge16(
                            context,
                            text: 'No ratings yet',
                            isTextWidget: true,
                            color: AppColors.kGreyColor,
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemCount: ratings.length,
                          separatorBuilder: (context, index) => Divider(
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                          itemBuilder: (context, index) {
                            final rating = ratings[index];
                            return RatingItem(
                              name: 'Passenger',
                              rating: rating.score,
                              time: rating.timeAgo,
                              comment: rating.comment,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
