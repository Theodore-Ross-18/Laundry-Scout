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
  double _searchRadius = 1.0; // Initial search radius in kilometers
  // bool _foundLaundryShops = false; // Track if any shops are found within the radius

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      setState(() {
        _locationPermissionMessage = "Please allow location access to view the nearby laundry shops in the map";
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
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
      });
      print('Current Location: Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}, Accuracy: ${position.accuracy}m');
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0); // Move map to current location and set zoom
      _fetchBusinessProfiles(radius: _searchRadius);
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Could not get your location: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusinessProfiles({double? radius}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      List<Map<String, dynamic>> allBusinessProfiles = List<Map<String, dynamic>>.from(response);
      List<Map<String, dynamic>> filteredProfiles = [];

      if (_currentPosition != null) {
        for (var business in allBusinessProfiles) {
          final lat = business['latitude'];
          final lng = business['longitude'];
          if (lat != null && lng != null) {
            final distance = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            );
            if (distance <= (radius ?? _searchRadius)) {
              filteredProfiles.add(business);
            }
          }
        }
      }

      setState(() {
        _businessProfiles = filteredProfiles;
        _isLoading = false;
        // _foundLaundryShops = filteredProfiles.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Error fetching business profiles: $e";
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Distance in kilometers
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(businessData['business_address'] ?? 'No address provided', style: const TextStyle(color: Colors.black)),
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
      backgroundColor: const Color(0xFF6F5ADC),
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
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 110.0,
                      ),
                      SizedBox(height: 20),
                      Text(_locationPermissionMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _requestLocationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F5ADC),
                          foregroundColor: Colors.white,
                        ),
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
                              key: ValueKey(_currentPosition), // Add key to force rebuild on location change
                              mapController: _mapController,
                              options: MapOptions(
                                center: _currentPosition != null
                                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                    : LatLng(0, 0), // Default to (0,0) or a sensible fallback
                                zoom: 13.0,
                                minZoom: 10.0,
                                maxZoom: 18.0,
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: const ['a', 'b', 'c'],
                                ),
                                if (_currentPosition != null)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                        useRadiusInMeter: true, // ✅ use meters instead of pixels
                                        radius: _searchRadius * 1000, // km → meters
                                        color: const Color(0xFF6F5ADC).withOpacity(0.2),
                                        borderColor: const Color(0xFF6F5ADC),
                                        borderStrokeWidth: 2,
                                      ),
                                    ],
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
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Search Radius: ${_searchRadius.toStringAsFixed(0)} km',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_searchRadius < 10.0) // Only show button if radius is less than max
                            SizedBox(
                              width: 200, // Adjust width as needed
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchRadius = (_searchRadius + 1.0).clamp(1.0, 10.0);
                                  });
                                  _fetchBusinessProfiles(radius: _searchRadius);
                                },
                                icon: const Icon(Icons.search), // Add an icon to the button
                                label: const Text('Locate Laundry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6F5ADC), // Use the theme color
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Adjust padding
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}