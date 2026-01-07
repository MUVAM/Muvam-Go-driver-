import 'package:muvam_rider/core/utils/app_logger.dart';

import 'lib/core/utils/wkb_decoder.dart';

void main() {
  // Test with your actual WKB data
  final wkbHex = "0101000020E6100000722C0A16CC7C1B4029A1C4D37DA61D40";

  AppLogger.log('Testing WKB decoder with: $wkbHex');

  final result = WKBDecoder.decodePoint(wkbHex);

  if (result != null) {
    AppLogger.log('Decoded coordinates:');
    AppLogger.log('Latitude: ${result['latitude']}');
    AppLogger.log('Longitude: ${result['longitude']}');
  } else {
    AppLogger.log('Failed to decode WKB data');
  }
}
