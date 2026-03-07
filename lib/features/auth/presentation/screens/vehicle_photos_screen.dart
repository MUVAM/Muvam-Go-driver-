import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/app_spacings.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/features/auth/presentation/widgets/photo_box_widget.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class VehiclePhotosScreen extends StatefulWidget {
  const VehiclePhotosScreen({super.key});

  @override
  State<VehiclePhotosScreen> createState() => _VehiclePhotosScreenState();
}

class _VehiclePhotosScreenState extends State<VehiclePhotosScreen> {
  final List<File?> _vehiclePhotos = [null, null, null];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _vehiclePhotos[index] = File(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _vehiclePhotos[index] = null;
    });
  }

  bool get _allPhotosUploaded {
    return _vehiclePhotos.every((photo) => photo != null);
  }

  void _continue() {
    if (_allPhotosUploaded) {
      Navigator.pop(context, _vehiclePhotos.whereType<File>().toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return AppScaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: themeManager.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeManager.getTextColor(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: MuvamTexts.titleMedium18(
          context,
          text: 'Vehicle Verification',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
          color: themeManager.getTextColor(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacings.k20,
                vertical: AppSpacings.k20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Vehicle Photo',
                    isTextWidget: true,
                    fontWeight: FontWeight.w700,
                    color: themeManager.getTextColor(context),
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'Upload three clear photo of your vehicle.',
                    isTextWidget: true,
                    color: themeManager.getSecondaryTextColor(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (index) {
                        return PhotoBoxWidget(
                          photo: _vehiclePhotos[index],
                          index: index,
                          themeManager: themeManager,
                          onTap: () => _vehiclePhotos[index] == null
                              ? _pickImage(index)
                              : null,
                          onRemove: () => _removeImage(index),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GestureDetector(
                onTap: _allPhotosUploaded ? _continue : null,
                child: Container(
                  width: double.infinity,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: _allPhotosUploaded
                        ? AppColors.kMainColor
                        : AppColors.kGreyColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Continue',
                      color: _allPhotosUploaded
                          ? AppColors.kWhiteColor
                          : Colors.grey.shade500,
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
      ),
    );
  }
}
