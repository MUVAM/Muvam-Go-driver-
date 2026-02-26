import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/vehicle_service.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';

class VehicleProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<String> _carMakes = [];
  List<String> _carModels = [];
  List<String> _carYears = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<String> get carMakes => _carMakes;
  List<String> get carModels => _carModels;
  List<String> get carYears => _carYears;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicleData(String token) async {
    AppLogger.log(
      '\n========== FETCHING VEHICLE DATA ==========',
      tag: 'VEHICLE_PROVIDER',
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vehicleService.getVehicles(token);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        if (data['vehicles'] != null && data['vehicles'] is List) {
          final vehicles = data['vehicles'] as List;

          AppLogger.log(
            'Processing ${vehicles.length} vehicles...',
            tag: 'VEHICLE_PROVIDER',
          );

          // Extract unique values from existing vehicles
          _carMakes = _vehicleService.extractCarMakes(vehicles);
          _carModels = _vehicleService.extractCarModels(vehicles);
          _carYears = _vehicleService.extractCarYears(vehicles);

          // If no years found in vehicles, generate default year options
          if (_carYears.isEmpty) {
            AppLogger.log(
              'No years found in vehicles, generating default options',
              tag: 'VEHICLE_PROVIDER',
            );
            _carYears = _vehicleService.generateYearOptions();
          }

          AppLogger.log(
            'Vehicle data processed successfully',
            tag: 'VEHICLE_PROVIDER',
          );
          AppLogger.log(
            'Car Makes: ${_carMakes.length}',
            tag: 'VEHICLE_PROVIDER',
          );
          AppLogger.log(
            'Car Models: ${_carModels.length}',
            tag: 'VEHICLE_PROVIDER',
          );
          AppLogger.log(
            'Car Years: ${_carYears.length}',
            tag: 'VEHICLE_PROVIDER',
          );
        } else {
          AppLogger.log(
            'No vehicles found, using default options',
            tag: 'VEHICLE_PROVIDER',
          );
          // Set default values if no vehicles exist
          _carYears = _vehicleService.generateYearOptions();
        }

        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch vehicle data';
        //Failed: $_errorMessage', tag: 'VEHICLE_PROVIDER');

        // Set default year options on error
        _carYears = _vehicleService.generateYearOptions();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      //Exception: $e', tag: 'VEHICLE_PROVIDER');

      // Set default year options on error
      _carYears = _vehicleService.generateYearOptions();
    } finally {
      _isLoading = false;
      notifyListeners();
      AppLogger.log(
        '========== VEHICLE DATA FETCH COMPLETE ==========\n',
        tag: 'VEHICLE_PROVIDER',
      );
    }
  }

  void clearVehicleData() {
    _carMakes = [];
    _carModels = [];
    _carYears = [];
    _errorMessage = null;
    notifyListeners();
  }
}
