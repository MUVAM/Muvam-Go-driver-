import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam_rider/core/utils/app_logger.dart';
import '../constants/url_constants.dart';

class VehicleService {
  Future<Map<String, dynamic>> getVehicles(String token) async {
    try {
      //Fetching vehicles from API...', tag: 'VEHICLE');

      final response = await http.get(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.registerVehicle}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log(
        'Vehicle API Response Status: ${response.statusCode}',
        tag: 'VEHICLE',
      );
      AppLogger.log(
        'Vehicle API Response Body: ${response.body}',
        tag: 'VEHICLE',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //Vehicles fetched successfully', tag: 'VEHICLE');
        return {'success': true, 'data': data};
      } else {
        AppLogger.log(
          'Failed to fetch vehicles: ${response.body}',
          tag: 'VEHICLE',
        );
        return {
          'success': false,
          'message': 'Failed to fetch vehicles: ${response.statusCode}',
        };
      }
    } catch (e) {
      //Error fetching vehicles: $e', tag: 'VEHICLE');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  List<String> extractCarMakes(List<dynamic> vehicles) {
    final makes = vehicles
        .map((v) => v['Make'] as String?)
        .where((make) => make != null && make.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    makes.sort();
    AppLogger.log(
      'Extracted ${makes.length} unique car makes: $makes',
      tag: 'VEHICLE',
    );
    return makes;
  }

  List<String> extractCarModels(List<dynamic> vehicles) {
    final models = vehicles
        .map((v) => v['ModelType'] as String?)
        .where((model) => model != null && model.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    models.sort();
    AppLogger.log(
      'Extracted ${models.length} unique car models: $models',
      tag: 'VEHICLE',
    );
    return models;
  }

  List<String> extractCarYears(List<dynamic> vehicles) {
    final years = vehicles
        .map((v) => v['Year'] as int?)
        .where((year) => year != null && year > 0)
        .map((year) => year.toString())
        .toSet()
        .toList();

    years.sort((a, b) => b.compareTo(a));
    AppLogger.log(
      'Extracted ${years.length} unique car years: $years',
      tag: 'VEHICLE',
    );
    return years;
  }

  List<String> generateYearOptions() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      20,
      (index) => (currentYear - index).toString(),
    );
    AppLogger.log(
      'Generated year options: ${years.length} years',
      tag: 'VEHICLE',
    );
    return years;
  }
}
