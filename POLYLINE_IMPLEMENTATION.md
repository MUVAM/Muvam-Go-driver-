# Polyline Implementation for Driver Navigation

## Overview
This implementation provides real-time polyline display from the driver's current location to the pickup location when a ride is accepted, and updates the polyline as the driver moves.

## Key Features

### 1. **Real-time Polyline Display**
- When a driver accepts a ride, a polyline is immediately drawn from their current location to the pickup location
- The polyline uses Google's Directions API to show the actual driving route (not just a straight line)
- Color coding: Green polyline for routes to pickup location, Blue polyline for routes to destination

### 2. **Dynamic Updates**
- The polyline updates every 5 seconds via timer
- Additional real-time updates when the driver moves more than 20 meters
- Driver location marker moves in real-time on the map

### 3. **Status-Based Routing**
- **Accepted/Arrived Status**: Shows route from driver to pickup location
- **Started Status**: Shows route from driver to destination
- **Completed/Cancelled**: Stops tracking and clears polylines

## Implementation Details

### Core Components

#### 1. RideTrackingService (`lib/core/services/ride_tracking_service.dart`)
- Manages real-time location tracking
- Handles polyline drawing using Google Directions API
- Updates map markers and camera position
- Sends location updates to backend

#### 2. HomeScreen Integration (`lib/features/home/presentation/screens/home_screen.dart`)
- Starts tracking when ride is accepted
- Updates UI with ETA and location information
- Handles ride status changes

#### 3. API Integration (`lib/core/services/api_service.dart`)
- `updateDriverLocation()`: Sends driver location to backend during ride
- Ride status management (accept, arrive, start, complete)

### Key Methods

#### `startRideTracking()`
```dart
// Initializes tracking with:
// - Pickup and destination markers
// - Real-time location updates (5-second intervals)
// - Position stream for immediate updates (20-meter threshold)
// - Initial polyline drawing
```

#### `_updateDriverLocation()`
```dart
// Updates on each location change:
// - Driver marker position
// - Polyline route (pickup vs destination based on status)
// - ETA calculation
// - Camera bounds to show both driver and target
// - Backend location sync
```

#### `_drawRoute()`
```dart
// Creates polyline using Google Directions API:
// - Fetches actual driving route points
// - Fallback to straight line if API fails
// - Color-coded based on route type (pickup/destination)
// - Dashed line pattern for better visibility
```

## User Experience Flow

### 1. **Ride Acceptance**
```
Driver accepts ride → startRideTracking() called
→ Markers added (pickup, destination, driver)
→ Initial polyline drawn to pickup location
→ Camera adjusted to show route
```

### 2. **Navigation to Pickup**
```
Driver moves → Location updates every 5 seconds
→ Polyline redrawn with new route
→ ETA updated and displayed
→ Green polyline shows route to pickup
```

### 3. **Arrival at Pickup**
```
Driver marks "Arrived" → Status changes to 'arrived'
→ Polyline still shows pickup location
→ Driver can start the ride
```

### 4. **Ride Started**
```
Driver starts ride → Status changes to 'started'
→ Polyline switches to destination route
→ Blue polyline shows route to destination
→ ETA updates for destination
```

### 5. **Ride Completion**
```
Driver completes ride → Status changes to 'completed'
→ Tracking stops
→ Polylines and markers cleared
→ Map returns to normal state
```

## Technical Configuration

### Google Maps API Setup
- API key configured in `UrlConstants.googleMapsApiKey`
- Directions API enabled for route calculation
- Maps SDK enabled for map display

### Location Permissions
- High accuracy location tracking
- Background location updates during active rides
- Automatic permission handling

### Performance Optimizations
- 5-second update intervals to balance accuracy and battery
- 20-meter distance filter for position stream
- Efficient polyline caching and updates
- Automatic cleanup when ride ends

## Error Handling

### API Failures
- Fallback to straight-line polyline if Directions API fails
- Graceful degradation with basic distance/ETA calculation

### Location Issues
- Handles location permission denials
- Continues with last known location if GPS unavailable
- Automatic retry mechanisms

### Network Issues
- Offline polyline display using cached route
- Background sync when connection restored

## Testing the Implementation

### 1. **Accept a Ride**
- Go online as a driver
- Wait for a ride request
- Accept the ride
- Observe green polyline from your location to pickup

### 2. **Move Around**
- Walk or drive while ride is active
- Watch polyline update in real-time
- Verify ETA changes as you move

### 3. **Status Changes**
- Mark as "Arrived" - polyline remains to pickup
- Start ride - polyline switches to destination (blue)
- Complete ride - tracking stops, polylines clear

## Customization Options

### Polyline Appearance
```dart
// In _drawRoute() method:
color: routeType == 'pickup' ? Colors.green : Colors.blue,
width: 6,
patterns: [PatternItem.dash(15), PatternItem.gap(8)],
```

### Update Frequencies
```dart
// Timer interval (currently 5 seconds):
Timer.periodic(Duration(seconds: 5), ...)

// Distance filter (currently 20 meters):
distanceFilter: 20,
```

### ETA Calculation
```dart
// Average speed assumption (currently 25 km/h):
final timeInHours = distanceInKm / 25;
```

This implementation provides a complete real-time navigation experience for drivers, with automatic polyline updates as they move toward pickup and destination locations.