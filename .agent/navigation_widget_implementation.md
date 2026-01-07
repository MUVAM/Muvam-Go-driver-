# Navigation Widget Implementation

## Overview
Added a navigation widget to the ride details sheet that allows drivers to open Google Maps with the appropriate destination based on the current ride status.

## Features

### Navigation Widget
- **Location**: Top-right corner of the ride details sheet
- **Visibility**: Shows for all ride statuses except 'completed'
- **Design**: 
  - Navigation icon on the left
  - Two-line text in the middle:
    - "Navigation" (bold)
    - "Open in map" (lighter)
  - Forward arrow icon on the right
  - Styled with app's main color and subtle background

### Smart Destination Selection
The widget intelligently determines which location to navigate to:

1. **Ride Status: 'accepted' or 'arrived'** (Before ride starts)
   - Opens Google Maps with **Pickup Location**
   - Helps driver navigate to where they need to pick up the passenger

2. **Ride Status: 'started'** (During ride)
   - Opens Google Maps with **Destination Location**
   - Helps driver navigate to where they need to drop off the passenger

## Implementation Details

### Files Modified
- `lib/features/home/presentation/screens/home_screen.dart`

### Changes Made

#### 1. Added `_openGoogleMaps()` Method
```dart
Future<void> _openGoogleMaps() async {
  try {
    // Determine which location to navigate to based on ride status
    String? destinationAddress;
    
    if (_rideStatus == 'started') {
      // If ride has started, navigate to destination
      destinationAddress = widget.ride['DestAddress'];
    } else {
      // If ride not started (accepted or arrived), navigate to pickup
      destinationAddress = widget.ride['PickupAddress'];
    }

    if (destinationAddress == null || destinationAddress.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Location address not available',
      );
      return;
    }

    // Create Google Maps URL with the destination address
    final encodedAddress = Uri.encodeComponent(destinationAddress);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      CustomFlushbar.showError(
        context: context,
        message: 'Could not open Google Maps',
      );
    }
  } catch (e) {
    AppLogger.error('Error opening Google Maps', error: e);
    CustomFlushbar.showError(
      context: context,
      message: 'Failed to open Google Maps',
    );
  }
}
```

**Key Features:**
- Uses `url_launcher` package to open Google Maps
- Encodes the address properly for URL
- Opens in external application mode (launches Google Maps app)
- Handles errors gracefully with user-friendly messages
- Logs errors for debugging

#### 2. Modified `build()` Method
- Wrapped the existing `Column` in a `Stack`
- Added a `Positioned` widget for the navigation button
- Positioned at `top: 0, right: 0` (top-right corner)
- Only shows when ride status is not 'completed'

#### 3. Navigation Widget Structure
```dart
Positioned(
  top: 0,
  right: 0,
  child: GestureDetector(
    onTap: _openGoogleMaps,
    child: Container(
      // Styled container with border and background
      child: Row(
        children: [
          Icon(Icons.navigation),  // Navigation icon
          Column(
            children: [
              Text('Navigation'),    // Bold title
              Text('Open in map'),   // Subtitle
            ],
          ),
          Icon(Icons.arrow_forward_ios),  // Arrow icon
        ],
      ),
    ),
  ),
)
```

## User Experience

### Before Ride Starts
1. Driver accepts a ride
2. Ride details sheet appears
3. Navigation widget is visible in top-right corner
4. Driver taps the widget
5. Google Maps opens with **pickup location**
6. Driver can use Google Maps features (directions, traffic, etc.)

### During Ride
1. Driver starts the ride
2. Navigation widget updates automatically
3. Driver taps the widget
4. Google Maps opens with **destination location**
5. Driver can navigate to drop-off point

### After Ride Completes
- Navigation widget is hidden (no longer needed)

## Technical Details

### Dependencies Used
- `url_launcher`: Already in project (used for opening external URLs)
- `Icons.navigation`: Flutter's built-in navigation icon
- `Icons.arrow_forward_ios`: Flutter's built-in arrow icon

### URL Format
```
https://www.google.com/maps/search/?api=1&query=<encoded_address>
```

This format:
- Works on both Android and iOS
- Opens the native Google Maps app
- Allows users to get directions, see traffic, etc.
- Handles address encoding automatically

### Error Handling
1. **Missing Address**: Shows error message if pickup/destination address is not available
2. **Cannot Launch URL**: Shows error if Google Maps cannot be opened
3. **General Errors**: Logs error and shows user-friendly message

## Styling

### Colors
- **Border & Icons**: App's main color (`ConstColors.mainColor`)
- **Background**: Main color with 10% opacity
- **Text**: Main color for title, grey for subtitle

### Dimensions
- **Padding**: 12w horizontal, 8h vertical
- **Border Width**: 1px
- **Border Radius**: 8r
- **Icon Sizes**: 20sp (navigation), 12sp (arrow)
- **Font Sizes**: 12sp (title), 10sp (subtitle)

### Font
- **Family**: Inter
- **Title Weight**: 700 (bold)
- **Subtitle Weight**: 400 (regular)

## Benefits

1. **Convenience**: Drivers can quickly open Google Maps without leaving the app
2. **Smart**: Automatically shows the right destination based on ride status
3. **Integrated**: Uses device's Google Maps app with all its features
4. **User-Friendly**: Clear visual design with icon and text
5. **Error-Proof**: Handles missing data and errors gracefully

## Future Enhancements (Optional)

1. **Direct Directions**: Could use `google_maps_url` package to open directions directly
2. **Coordinates**: Could use lat/long instead of addresses for more accuracy
3. **Alternative Apps**: Could support Waze, Apple Maps, etc.
4. **In-App Navigation**: Could integrate turn-by-turn navigation within the app

## Testing

### Test Scenarios

1. **Test Pickup Navigation**:
   - Accept a ride
   - Tap navigation widget
   - Verify Google Maps opens with pickup location

2. **Test Destination Navigation**:
   - Start a ride
   - Tap navigation widget
   - Verify Google Maps opens with destination location

3. **Test Missing Address**:
   - Create a ride with missing address
   - Tap navigation widget
   - Verify error message appears

4. **Test Completed Ride**:
   - Complete a ride
   - Verify navigation widget is hidden

## Notes

- The widget uses the `PickupAddress` and `DestAddress` fields from the ride data
- These addresses are already being fetched and displayed in the app
- The implementation is non-intrusive and doesn't affect existing functionality
- The widget is responsive and adapts to different screen sizes using ScreenUtil
