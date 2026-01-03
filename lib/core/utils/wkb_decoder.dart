import 'dart:typed_data';
import 'package:muvam_rider/core/utils/app_logger.dart';

/// Utility class to decode WKB (Well-Known Binary) geometry data from PostGIS

class WKBDecoder {
  static Map<String, double>? decodePoint(String wkbHex) {
    try {
      wkbHex = wkbHex.replaceAll(' ', '').toUpperCase();

      final bytes = _hexToBytes(wkbHex);
      AppLogger.log('WKB bytes length: ${bytes.length}');
      AppLogger.log(
        'First few bytes: ${bytes.take(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      if (bytes.length < 25) {
        AppLogger.log('WKB too short: ${bytes.length} bytes, need at least 25');
        return null;
      }

      final byteOrder = bytes[0];
      final isLittleEndian = byteOrder == 1;
      AppLogger.log(
        'Byte order: $byteOrder (${isLittleEndian ? "little" : "big"} endian)',
      );

      final data = ByteData.sublistView(Uint8List.fromList(bytes));

      final geomType = data.getUint32(
        1,
        isLittleEndian ? Endian.little : Endian.big,
      );
      AppLogger.log('Geometry type: $geomType');

      final srid = data.getUint32(
        5,
        isLittleEndian ? Endian.little : Endian.big,
      );
      AppLogger.log('SRID: $srid');

      final longitude = data.getFloat64(
        9,
        isLittleEndian ? Endian.little : Endian.big,
      );

      final latitude = data.getFloat64(
        17,
        isLittleEndian ? Endian.little : Endian.big,
      );

      AppLogger.log('Decoded coordinates: lat=$latitude, lng=$longitude');

      if (latitude.abs() > 90 || longitude.abs() > 180) {
        AppLogger.log(
          'Invalid coordinates detected: lat=$latitude, lng=$longitude',
        );
        return null;
      }

      return {'latitude': latitude, 'longitude': longitude};
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
