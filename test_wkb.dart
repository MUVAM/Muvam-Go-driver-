import 'package:muvam_rider/core/utils/app_logger.dart';

import 'lib/core/utils/wkb_decoder.dart';

void main() {
  // Test with your actual WKB data
  final wkbHex = "0101000020E6100000722C0A16CC7C1B4029A1C4D37DA61D40";

  //Testing WKB decoder with: $wkbHex');

  final result = WKBDecoder.decodePoint(wkbHex);

  if (result != null) {
    //Decoded coordinates:');
    //Latitude: ${result['latitude']}');
    //Longitude: ${result['longitude']}');
  } else {
    //Failed to decode WKB data');
  }
}
