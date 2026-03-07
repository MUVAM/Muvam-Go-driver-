import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam_rider/core/constants/app_colors.dart';
import 'package:muvam_rider/core/constants/muvam_text.dart';
import 'package:muvam_rider/core/constants/theme_manager.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';

class CreateLocationField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onLocationPointChanged;
  final Function(String) onStateChanged;
  final ThemeManager themeManager;

  const CreateLocationField({
    super.key,
    required this.controller,
    required this.onLocationPointChanged,
    required this.onStateChanged,
    required this.themeManager,
  });

  @override
  State<CreateLocationField> createState() => _CreateLocationFieldState();
}

class _CreateLocationFieldState extends State<CreateLocationField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: 'Location',
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.kFieldColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tap to get current location',
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.kGreyColor,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _getCurrentLocation(context),
                ),
              ),
              GestureDetector(
                onTap: () => _getCurrentLocation(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.my_location,
                    size: 20.sp,
                    color: AppColors.kMainColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    try {
      setState(() {
        widget.controller.text = 'Getting location...';
      });
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          widget.controller.clear();
        });
        if (!context.mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            widget.controller.clear();
          });
          if (!context.mounted) return;
          CustomFlushbar.showError(
            context: context,
            message: 'Location permission denied',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          widget.controller.clear();
        });
        if (!context.mounted) return;
        CustomFlushbar.showError(
          context: context,
          message:
              'Location permission permanently denied. Please enable in settings.',
        );
        return;
      }
      Position? position;
      try {
        position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                throw TimeoutException(
                  'Location fetch timed out after 20 seconds',
                );
              },
            );
      } on TimeoutException catch (e) {
        setState(() {
          widget.controller.clear();
        });
        if (!context.mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location request timed out. Please try again.',
        );
        return;
      }

      String locationPoint =
          'POINT(${position.longitude} ${position.latitude})';
      widget.onLocationPointChanged(locationPoint);

      String fallbackCity =
          'City_${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}';
      widget.onStateChanged(fallbackCity);

      String address = '';
      bool geocodingSuccessful = false;

      try {
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            ).timeout(const Duration(seconds: 10));

            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];

              String? city =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  place.subLocality;

              if (city != null && city.isNotEmpty) {
                widget.onStateChanged(city);
              }

              List<String> addressParts = [];

              if (place.street != null && place.street!.isNotEmpty) {
                addressParts.add(place.street!);
              }
              if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                addressParts.add(place.subLocality!);
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                addressParts.add(place.locality!);
              }
              if (place.administrativeArea != null &&
                  place.administrativeArea!.isNotEmpty) {
                addressParts.add(place.administrativeArea!);
              }
              if (place.country != null && place.country!.isNotEmpty) {
                addressParts.add(place.country!);
              }

              address = addressParts.join(', ');

              if (address.isEmpty && city != null) {
                address = city;
              }

              geocodingSuccessful = true;
              break;
            }
          } on TimeoutException catch (e) {
            if (attempt < 2) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e) {
            if (attempt < 2) {
              await Future.delayed(const Duration(seconds: 1));
            } else {
              break;
            }
          }
        }
      } catch (e) {}
      if (geocodingSuccessful && address.isNotEmpty) {
        setState(() {
          widget.controller.text = address;
        });
        if (!context.mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location captured successfully',
        );
      } else {
        setState(() {
          widget.controller.text =
              'Lat: ${position!.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });
        if (!context.mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location saved (GPS coordinates)',
        );
      }
    } on LocationServiceDisabledException catch (e) {
      setState(() {
        widget.controller.clear();
        widget.onLocationPointChanged('');
      });
      if (!context.mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Location services are disabled. Please enable GPS.',
      );
    } catch (e) {
      setState(() {
        widget.controller.clear();
        widget.onLocationPointChanged('');
        widget.onStateChanged('');
      });

      if (!context.mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }
}
