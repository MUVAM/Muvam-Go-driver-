import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam_rider/core/constants/colors.dart';
import 'package:muvam_rider/core/constants/fonts.dart';
import 'package:provider/provider.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';

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
      // Return the list of photos to the previous screen
      Navigator.pop(context, _vehiclePhotos.whereType<File>().toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: themeManager.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: themeManager.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeManager.getTextColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vehicle Verification',
          style: TextStyle(
            fontFamily: ConstFonts.inter,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: themeManager.getTextColor(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Photo',
                    style: TextStyle(
                      fontFamily: ConstFonts.inter,
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                      color: themeManager.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Upload three clear photo of your vehicle.',
                    style: TextStyle(
                      fontFamily: ConstFonts.inter,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      color: themeManager.getSecondaryTextColor(context),
                    ),
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
                        return _buildPhotoBox(index, themeManager);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: GestureDetector(
                onTap: _allPhotosUploaded ? _continue : null,
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _allPhotosUploaded
                        ? Color(ConstColors.mainColor)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: ConstFonts.inter,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: _allPhotosUploaded
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoBox(int index, ThemeManager themeManager) {
    final photo = _vehiclePhotos[index];
    
    return GestureDetector(
      onTap: () => photo == null ? _pickImage(index) : null,
      child: Container(
        width: 102.w,
        height: 102.w,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: photo != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.file(
                      photo,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4.h,
                    right: 4.w,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  Icons.add,
                  size: 40.sp,
                  color: Colors.grey.shade400,
                ),
              ),
      ),
    );
  }
}
