import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentAddress = 'Fetching location...';
  bool _isLoading = true;
  
  // Map and location variables
  MapController? _mapController;
  LatLng? _selectedPosition;
  bool _locationPermissionGranted = false;
  List<Marker> _markers = [];
  
  // Error handling
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Permission.location.status;
    if (permission.isGranted) {
      _locationPermissionGranted = true;
      await _getCurrentLocation();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
        _isLoading = true;
      });
      await _getCurrentLocation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to select your address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        
        return address.isNotEmpty ? address : 'Location selected';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return 'Location selected';
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('_getCurrentLocation called for address selection');
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint('Got GPS position: ${position.latitude}, ${position.longitude}');
      
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
      });
      
      String address = await _getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      setState(() {
        _currentAddress = address;
        _isLoading = false;
      });
      
      // Move map to current location
      if (_mapController != null && _selectedPosition != null) {
        _mapController!.move(_selectedPosition!, 16);
      }
      
      // Create markers
      await _createMarkers();
      
    } on TimeoutException catch (e) {
      debugPrint('Location timeout: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Location request timed out. Please check your location settings.';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to get your location. Please check your location settings or try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _createMarkers() async {
    if (_selectedPosition == null) return;

    List<Marker> markers = [];
    
    // Add selected location marker (purple pin)
    markers.add(
      Marker(
        point: _selectedPosition!,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6F5ADC),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Center(
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
    
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedPosition = position;
    });
    
    String address = await _getAddressFromCoordinates(
      position.latitude, 
      position.longitude
    );
    
    setState(() {
      _currentAddress = address;
    });
    
    await _createMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F5ADC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laundry Scout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Map Area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Actual FlutterMap
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedPosition ?? const LatLng(14.5995, 121.0364), // Default to Manila
                                initialZoom: 16,
                                onTap: (_, point) => _onMapTapped(point),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.laundryscout.app',
                                ),
                                MarkerLayer(
                                  markers: _markers,
                                ),
                              ],
                            ),
                            // Permission request overlay
                            if (!_locationPermissionGranted)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 48,
                                          color: Color(0xFF6F5ADC),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Location Permission Required',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Please enable location permission to select your address',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _requestLocationPermission,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6F5ADC),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Enable Location',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // Error overlay
                            if (_hasError)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Location Error',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _errorMessage,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _getCurrentLocation,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6F5ADC),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Retry',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // Current location button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6F5ADC),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _getCurrentLocation,
                                ),
                              ),
                            ),
                            // Map instruction
                            if (!_hasError && _locationPermissionGranted)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Tap on the map to select your location',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6F5ADC),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Search and confirm section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search your location',
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Color(0xFF6F5ADC),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Instruction text
                        const Text(
                          'Hold the red pin and drag it to your desired location.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Confirm button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_selectedPosition != null
                                    ? () {
                                        Navigator.pop(context, {
                                          'address': _currentAddress,
                                          'coordinates': _selectedPosition,
                                        });
                                      }
                                    : null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6F5ADC),
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Confirm Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}