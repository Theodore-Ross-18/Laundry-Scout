import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _hasPermission = false;
  String _permissionStatus = 'Checking permission...';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
      _permissionStatus = 'Checking permission...';
    });

    // Check location permission
    PermissionStatus permission = await Permission.location.request();
    
    if (permission.isGranted) {
      setState(() {
        _hasPermission = true;
        _permissionStatus = 'Location permission granted';
      });
      await _getCurrentLocation();
    } else if (permission.isDenied) {
      setState(() {
        _hasPermission = false;
        _permissionStatus = 'Location permission denied';
        _isLoading = false;
      });
    } else if (permission.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _permissionStatus = 'Location permission permanently denied. Please enable in settings.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _currentPosition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedPosition = latlng;
    });
  }

  void _requestPermissionAgain() {
    _checkLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
        backgroundColor: const Color(0xFF6F5ADC),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : _buildMapView(),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 20),
            Text(
              _permissionStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissionAgain,
              child: const Text('Request Permission Again'),
            ),
            if (_permissionStatus.contains('permanently denied')) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open App Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Location Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Location:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedPosition != null) ...[
                Text(
                  'Latitude: ${_selectedPosition!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Longitude: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ] else
                const Text(
                  'No location selected',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),

        // Map Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _currentPosition ?? const LatLng(14.5995, 120.9842), // Default to Manila
                  initialZoom: 15.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.laundryscout.app',
                  ),
                  if (_selectedPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),

        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instructions:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Tap anywhere on the map to place the red pin\n• The pin represents your custom location\n• Latitude and longitude will update automatically\n• Drag the map to explore different areas',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Test entry point - uncomment to run this screen individually
void main() {
  runApp(const MaterialApp(
    home: LocationTestScreen(),
    debugShowCheckedModeBanner: false,
  ));
}