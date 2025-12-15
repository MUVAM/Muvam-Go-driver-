import 'lib/core/utils/wkb_decoder.dart';

void main() {
  // Test with your actual WKB data
  final wkbHex = "0101000020E6100000722C0A16CC7C1B4029A1C4D37DA61D40";
  
  print('Testing WKB decoder with: $wkbHex');
  
  final result = WKBDecoder.decodePoint(wkbHex);
  
  if (result != null) {
    print('Decoded coordinates:');
    print('Latitude: ${result['latitude']}');
    print('Longitude: ${result['longitude']}');
  } else {
    print('Failed to decode WKB data');
  }
}