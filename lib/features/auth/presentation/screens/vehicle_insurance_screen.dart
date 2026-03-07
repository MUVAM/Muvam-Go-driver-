import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/extension.dart';
import 'package:muvam_rider/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam_rider/layouts/presentation/shared/bottom_padding.dart';

class VehicleInsuranceScreen extends StatefulWidget {
  const VehicleInsuranceScreen({super.key});

  @override
  State<VehicleInsuranceScreen> createState() => _VehicleInsuranceScreenState();
}

class _VehicleInsuranceScreenState extends State<VehicleInsuranceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      AppLogger.log('Error initializing camera: $e');
    }
  }

  Future<void> _captureDocument() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      AppLogger.log('Error capturing image: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kBlackColor,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(child: CameraPreview(_cameraController!))
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.kWhiteColor),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.kBlackColor.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.kWhiteColor,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'Vehicle Verification',
                        isTextWidget: true,
                        center: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kWhiteColor,
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 320.w,
                    height: 220.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.kWhiteColor.withOpacity(0.8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kBlackColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: MuvamTexts.bodyMedium14(
                      context,
                      text: 'Align the document within the frame',
                      isTextWidget: true,
                      center: true,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.kBlackColor.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MuvamTexts.titleLarge22(
                      context,
                      text: 'Vehicle Insurance',
                      isTextWidget: true,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kWhiteColor,
                    ),
                    SizedBox(height: 8.h),
                    MuvamTexts.bodySmall12(
                      context,
                      text:
                          'Take a clear photo of your vehicle insurance document.',
                      isTextWidget: true,
                      center: true,
                      color: AppColors.kWhiteColor,
                    ),
                    SizedBox(height: 30.h),
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureDocument,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.kWhiteColor,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: _isCapturing
                              ? const CircularProgressIndicator(
                                  color: AppColors.kWhiteColor,
                                  strokeWidth: 3,
                                )
                              : Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: const BoxDecoration(
                                    color: AppColors.kWhiteColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    DeviceBottomPadding(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
