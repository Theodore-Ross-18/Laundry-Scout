import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_detail_screen.dart'; // Import the business detail screen

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationPermissionMessage = "Location permission not granted.";
  List<Map<String, dynamic>> _businessProfiles = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      setState(() {
        _locationPermissionMessage = "Location permissions are denied. Please allow location access to view the map.";
        _isLoading = false;
      });
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionMessage = "Location permissions are permanently denied. Please enable them in your device settings.";
        _isLoading = false;
      });
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionMessage = "Location permission not granted.";
        _isLoading = false;
      });
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationPermissionMessage = "";
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      _fetchBusinessProfiles();
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Could not get your location: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusinessProfiles() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      setState(() {
        _businessProfiles = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Error fetching business profiles: $e";
        _isLoading = false;
      });
    }
  }

  void _onTapBusinessMarker(Map<String, dynamic> businessData) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessData['business_name'] ?? 'Unknown Business',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(businessData['business_address'] ?? 'No address provided'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusinessDetailScreen(businessData: businessData),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Laundry Shops'),
        backgroundColor: const Color(0xFF6F5ADC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_locationPermissionMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _requestLocationPermission,
                        child: const Text('Allow Location Access'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: const ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: [
                                    // User's current location marker
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.blue,
                                        size: 40.0,
                                      ),
                                    ),
                                    // Business markers
                                    ..._businessProfiles.map((business) {
                                      final lat = business['latitude'];
                                      final lng = business['longitude'];
                                      if (lat != null && lng != null) {
                                        return Marker(
                                          width: 80.0,
                                          height: 80.0,
                                          point: LatLng(lat, lng),
                                          child: GestureDetector(
                                            onTap: () => _onTapBusinessMarker(business),
                                            child: const Icon(
                                              Icons.local_laundry_service,
                                              color: Colors.green,
                                              size: 40.0,
                                            ),
                                          ),
                                        );
                                      }
                                      return Marker(point: LatLng(0,0), child: Container()); // Placeholder for null lat/lng
                                    }).toList(),
                                  ],
                                ),
                              ],
                            ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.my_location, color: Colors.blue, size: 20.0),
                            const SizedBox(width: 5),
                            const Text('You', style: TextStyle(color: Colors.black)),
                            const SizedBox(width: 20),
                            const Icon(Icons.local_laundry_service, color: Colors.green, size: 20.0),
                            const SizedBox(width: 5),
                            const Text('Laundry Shop', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}