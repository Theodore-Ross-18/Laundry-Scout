import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:laundry_scout/services/location_service.dart';

class PickDropMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PickDropMapScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<PickDropMapScreen> createState() => _PickDropMapScreenState();
}

class _PickDropMapScreenState extends State<PickDropMapScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _hasPermission = false;
  String _permissionStatus = 'Checking permission...';
  final MapController _mapController = MapController();

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

    final permissionGranted = await LocationService.requestLocationPermission();
    
    if (permissionGranted) {
      setState(() {
        _hasPermission = true;
        _permissionStatus = 'Location permission granted';
      });
      await _getCurrentLocation();
    } else {
      final status = await Permission.location.status;
      setState(() {
        _hasPermission = false;
        if (status.isDenied) {
          _permissionStatus = 'Location permission denied';
        } else if (status.isPermanentlyDenied) {
          _permissionStatus = 'Location permission permanently denied. Please enable in settings.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      
      setState(() {
        if (position != null) {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _selectedPosition = _currentPosition;
          _mapController.move(_selectedPosition!, 15.0); // Move map to current location
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

  Future<void> _saveLocationToSupabase() async {
    if (_selectedPosition != null) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('user_profiles')
              .update({
                'latitude': _selectedPosition!.latitude,
                'longitude': _selectedPosition!.longitude,
              })
              .eq('id', user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location saved successfully!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving location: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Up and Drop Off Location'),
        backgroundColor: const Color(0xFF5A35E3),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveLocationToSupabase();
              Navigator.of(context).pop(_selectedPosition);
            },
          ),
      ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue)) // Changed color to blue
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : _buildMapView(),
      backgroundColor: const Color(0xFF5A35E3),
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
                  center: _selectedPosition ?? _currentPosition ?? const LatLng(14.5995, 120.9842), // Default to Manila
                  zoom: 15.0,
                  onTap: _onMapTap,
                ),
                mapController: _mapController,
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