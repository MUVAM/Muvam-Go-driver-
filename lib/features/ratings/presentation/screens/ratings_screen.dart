import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/images.dart';
import 'package:muvam_rider/core/services/api_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/features/profile/data/providers/profile_provider.dart';
import 'package:muvam_rider/features/ratings/data/models/rating_model.dart';
import 'package:muvam_rider/features/ratings/presentation/widgets/rating_item.dart';
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
    AppLogger.log('═══════════════════════════════════════', tag: 'RATINGS');
    AppLogger.log('🔵 LOADING RATINGS STARTED', tag: 'RATINGS');
    AppLogger.log('═══════════════════════════════════════', tag: 'RATINGS');
    
    try {
      AppLogger.log('📱 Getting SharedPreferences...', tag: 'RATINGS');
      final prefs = await SharedPreferences.getInstance();
      
      final token = prefs.getString('auth_token');
      
      // Try to get user_id as int first, then as string
      int? userId;
      try {
        userId = prefs.getInt('user_id');
      } catch (e) {
        // If getInt fails (because it's stored as String), try getString
        final userIdStr = prefs.getString('user_id');
        if (userIdStr != null) {
          userId = int.tryParse(userIdStr);
        }
      }
      
      AppLogger.log('🔑 Token exists: ${token != null}', tag: 'RATINGS');
      if (token != null) {
        AppLogger.log('🔑 Token preview: ${token.substring(0, 20)}...', tag: 'RATINGS');
      }
      AppLogger.log('👤 User ID: $userId', tag: 'RATINGS');
      AppLogger.log('👤 User ID type: ${userId.runtimeType}', tag: 'RATINGS');

      if (token == null || userId == null) {
        AppLogger.log('❌ Missing token or userId - stopping', tag: 'RATINGS');
        AppLogger.log('   Token is null: ${token == null}', tag: 'RATINGS');
        AppLogger.log('   UserId is null: ${userId == null}', tag: 'RATINGS');
        setState(() => isLoading = false);
        return;
      }

      AppLogger.log('📤 Calling ApiService.getUserRatings...', tag: 'RATINGS');
      AppLogger.log('   Endpoint: users/$userId/ratings', tag: 'RATINGS');
      
      final response = await ApiService.getUserRatings(token, userId);
      
      AppLogger.log('📥 API Response received:', tag: 'RATINGS');
      AppLogger.log('   Success: ${response['success']}', tag: 'RATINGS');
      AppLogger.log('   Data: ${response['data']}', tag: 'RATINGS');
      AppLogger.log('   Message: ${response['message']}', tag: 'RATINGS');
      
      if (response['success']) {
        AppLogger.log('✅ Response successful, parsing data...', tag: 'RATINGS');
        
        final ratingResponse = RatingResponse.fromJson(response['data']);
        
        AppLogger.log('📊 Parsed ${ratingResponse.ratings.length} ratings', tag: 'RATINGS');
        
        setState(() {
          ratings = ratingResponse.ratings;
          isLoading = false;
        });
        
        AppLogger.log('✅ State updated - isLoading: false', tag: 'RATINGS');
        AppLogger.log('✅ Ratings count: ${ratings.length}', tag: 'RATINGS');
      } else {
        AppLogger.log('❌ API returned success: false', tag: 'RATINGS');
        AppLogger.log('   Error message: ${response['message']}', tag: 'RATINGS');
        setState(() => isLoading = false);
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌❌❌ EXCEPTION IN _loadRatings ❌❌❌', tag: 'RATINGS');
      AppLogger.log('Error: $e', tag: 'RATINGS');
      AppLogger.log('Error type: ${e.runtimeType}', tag: 'RATINGS');
      AppLogger.log('Stack trace: $stackTrace', tag: 'RATINGS');
      setState(() => isLoading = false);
    } finally {
      AppLogger.log('═══════════════════════════════════════', tag: 'RATINGS');
      AppLogger.log('🔵 LOADING RATINGS COMPLETED', tag: 'RATINGS');
      AppLogger.log('   Final isLoading: $isLoading', tag: 'RATINGS');
      AppLogger.log('   Final ratings count: ${ratings.length}', tag: 'RATINGS');
      AppLogger.log('═══════════════════════════════════════', tag: 'RATINGS');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
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
                      Expanded(
                        child: Center(
                          child: Text(
                            'Ratings',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
                profileProvider.userProfilePhoto.isNotEmpty
                    ? CircleAvatar(
                        radius: 40.r,
                        backgroundImage:
                            NetworkImage(profileProvider.userProfilePhoto),
                      )
                    : Image.asset(ConstImages.avatar, width: 80.w, height: 80.h),
                SizedBox(height: 20.h),
                Text(
                  profileProvider.userName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 15.h),
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
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What your passengers said',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        letterSpacing: -0.2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(ConstColors.mainColor),
                          ),
                        )
                      : ratings.isEmpty
                          ? Center(
                              child: Text(
                                'No ratings yet',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
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
