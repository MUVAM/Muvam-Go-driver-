import 'dart:typed_data';
import 'package:muvam_rider/core/utils/app_logger.dart';

/// Utility class to decode WKB (Well-Known Binary) geometry data from PostGIS

class WKBDecoder {
  /// Decodes a WKB (Well-Known Binary) hex string to latitude and longitude
  /// Format: POINT(longitude latitude) in SRID 4326 (WGS84)
  static Map<String, double>? decodePoint(String wkbHex) {
    try {
      // Remove any whitespace and convert to uppercase
      wkbHex = wkbHex.replaceAll(' ', '').toUpperCase();
      
      // Convert hex string to bytes
      final bytes = _hexToBytes(wkbHex);
      AppLogger.log('WKB bytes length: ${bytes.length}');
      AppLogger.log('First few bytes: ${bytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      if (bytes.length < 25) {
        AppLogger.log('WKB too short: ${bytes.length} bytes, need at least 25');
        return null;
      }
      
      // Read byte order (little endian = 1, big endian = 0)
      final byteOrder = bytes[0];
      final isLittleEndian = byteOrder == 1;
      AppLogger.log('Byte order: $byteOrder (${isLittleEndian ? "little" : "big"} endian)');
      
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      
      // PostGIS WKB format for 25 bytes:
      // Byte 0: Endianness
      // Bytes 1-4: Geometry type (with SRID flag)
      // Bytes 5-8: SRID  
      // Bytes 9-16: X coordinate (longitude)
      // Bytes 17-24: Y coordinate (latitude)
      
      // Read geometry type
      final geomType = data.getUint32(1, isLittleEndian ? Endian.little : Endian.big);
      AppLogger.log('Geometry type: $geomType');
      
      // Read SRID
      final srid = data.getUint32(5, isLittleEndian ? Endian.little : Endian.big);
      AppLogger.log('SRID: $srid');
      
      // Read longitude (X coordinate) - 8 bytes double at offset 9
      final longitude = data.getFloat64(9, isLittleEndian ? Endian.little : Endian.big);
      
      // Read latitude (Y coordinate) - 8 bytes double at offset 17
      final latitude = data.getFloat64(17, isLittleEndian ? Endian.little : Endian.big);
      
      AppLogger.log('Decoded coordinates: lat=$latitude, lng=$longitude');
      
      // Validate coordinates are reasonable
      if (latitude.abs() > 90 || longitude.abs() > 180) {
        AppLogger.log('Invalid coordinates detected: lat=$latitude, lng=$longitude');
        return null;
      }
      
      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      AppLogger.log('Error decoding WKB: $e');
      return null;
    }
  }
  
  static List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      final hexByte = hex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    return bytes;
  }
}