import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/url_constants.dart';

class LocationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<List<Map<String, dynamic>>> getFavouriteLocations() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch favourite locations');
    }
  }

  Future<void> addFavouriteLocation(Map<String, dynamic> locationData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(locationData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add favourite location');
    }
  }

  Future<void> deleteFavouriteLocation(int favId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(
        '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$favId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete favourite location');
    }
  }

  Future<void> saveRecentLocation(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentLocations =
        prefs.getStringList('recent_locations') ?? [];

    final locationData = jsonEncode({'name': name, 'address': address});
    recentLocations.removeWhere((item) => jsonDecode(item)['name'] == name);
    recentLocations.insert(0, locationData);

    if (recentLocations.length > 10) {
      recentLocations = recentLocations.take(10).toList();
    }

    await prefs.setStringList('recent_locations', recentLocations);
  }

  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLocations = prefs.getStringList('recent_locations') ?? [];

    return recentLocations.map((item) {
      final data = jsonDecode(item);
      return {'name': data['name'], 'address': data['address']};
    }).toList();
  }
}
