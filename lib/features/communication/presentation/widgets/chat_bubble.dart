import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.kMainColor
              : AppColors.kGreyColor.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: isMe ? Radius.circular(5.r) : Radius.circular(0),
            topRight: isMe ? Radius.circular(0) : Radius.circular(5.r),
            bottomRight: Radius.circular(5.r),
            bottomLeft: Radius.circular(5.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MuvamTexts.bodyMedium14(
              context,
              text: text,
              isTextWidget: true,
              fontWeight: FontWeight.w400,
              color: isMe ? AppColors.kWhiteColor : AppColors.kBlackColor,
            ),
            SizedBox(height: 5.h),
            MuvamTexts.bodySmall12(
              context,
              text: time,
              isTextWidget: true,
              fontWeight: FontWeight.w500,
              color: AppColors.kBlackColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
