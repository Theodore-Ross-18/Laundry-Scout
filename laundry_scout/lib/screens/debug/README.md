# Location Test Screen

This is a debug/test screen for testing location functionality in the Laundry Scout app.

## Features

- **Location Permission Handling**: Requests and manages location permissions
- **Interactive Map**: Displays an OpenStreetMap with tap-to-place functionality
- **Draggable Pin**: Red location pin that can be moved by tapping on the map
- **Real-time Coordinates**: Displays latitude and longitude of the selected location
- **Permission Status**: Shows current permission status and provides options to request again

## How to Run Individually

### Method 1: Using the Test Runner (Recommended)
1. Open `lib/screens/debug/location_test_runner.dart`
2. Right-click and select "Run" or use the run button in your IDE
3. This will launch the location test as a standalone app

### Method 2: Using the Main Location Test File
1. Open `lib/screens/debug/location_test.dart`
2. Uncomment the main function at the bottom of the file
3. Set this file as your main entry point
4. Run the file

### Method 3: Integration Testing
You can also navigate to this screen from within the main app by:
1. Adding a navigation route to this screen
2. Creating a button or menu item that pushes this screen

## Usage Instructions

1. **Grant Permission**: When the app starts, it will request location permission
2. **View Current Location**: If permission is granted, the map will center on your current location
3. **Select Custom Location**: Tap anywhere on the map to place the red pin
4. **View Coordinates**: The latitude and longitude of the selected location will be displayed above the map
5. **Re-request Permission**: If permission is denied, use the "Request Permission Again" button
6. **Open Settings**: If permission is permanently denied, use "Open App Settings" to manually enable it

## Dependencies Used

- `flutter_map`: For displaying the interactive map
- `latlong2`: For latitude/longitude calculations
- `geolocator`: For getting the device's current location
- `permission_handler`: For managing location permissions

## Testing Scenarios

1. **Permission Granted**: Test normal operation with location permission
2. **Permission Denied**: Test the app's behavior when permission is denied
3. **Permission Permanently Denied**: Test the settings navigation functionality
4. **Location Accuracy**: Test the accuracy of the coordinates displayed
5. **Map Interaction**: Test tapping on different areas of the map

## Notes

- The map uses OpenStreetMap tiles (requires internet connection)
- Default location is set to Manila (14.5995, 120.9842) if no location is available
- The red pin is purely visual and doesn't support actual dragging, but responds to map taps
- Coordinates are displayed with 6 decimal places for precision