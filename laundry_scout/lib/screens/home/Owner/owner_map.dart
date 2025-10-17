import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class OwnerMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const OwnerMapScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _hasPermission = false;
  String _permissionStatus = 'Checking permission...';

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
      _permissionStatus = 'Checking permission...';
    });

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
        if (_selectedPosition == null) {
          _selectedPosition = _currentPosition;
        }
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
        title: const Text('Select Shop Location'),
        backgroundColor: const Color(0xFF5A35E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedPosition);
            },
          ),
        ],
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
                  initialCenter: _selectedPosition ?? _currentPosition ?? const LatLng(14.5995, 120.9842),
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
      const SizedBox(height: 16),
      ],
    );
  }
}