import 'dart:ui';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_detail_screen.dart';

String _getTileLayerUrlTemplate(MapType mapType) {
  switch (mapType) {
    case MapType.satellite:
      
      return "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}";
    case MapType.terrain:
      
      return "https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}";
    case MapType.defaultMap:
      return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
  }
}

class AnimatedLocationPin extends StatefulWidget {
  const AnimatedLocationPin({super.key});

  @override
  State<AnimatedLocationPin> createState() => _AnimatedLocationPinState();
}

class _AnimatedLocationPinState extends State<AnimatedLocationPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF5A35E3),
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LocationPermissionOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRequestPermission;
  final MapType selectedMapType;

  const LocationPermissionOverlay({
    super.key,
    required this.message,
    required this.onRequestPermission,
    required this.selectedMapType,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        Positioned.fill(
          child: FlutterMap(
            options: const MapOptions(
              center: LatLng(12.8797, 121.7740), 
              zoom: 5.9, 
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileLayerUrlTemplate(selectedMapType),
                subdomains: const ['a', 'b', 'c'],
              ),
            ],
          ),
        ),
        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedLocationPin(),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Location Access Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A35E3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onRequestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A35E3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Allow Location Access',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum MapType {
  defaultMap,
  satellite,
  terrain,
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationPermissionMessage = "Location permission not granted.";
  String? _currentAddress;
  List<Map<String, dynamic>> _businessProfiles = [];
  final MapController _mapController = MapController();
  double _searchRadius = 1.0; 
  MapType _selectedMapType = MapType.defaultMap; 

  void _onMapTypeChanged(MapType? newMapType) {
    if (newMapType != null) {
      setState(() {
        _selectedMapType = newMapType;
      });
    }
  }

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
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude
      );
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.locality}, ${place.administrativeArea}";
        });
        // Update user_profiles table with current location and address
        final user = Supabase.instance.client.auth.currentUser;
          if (user != null && _currentAddress != null && _currentAddress!.isNotEmpty) {
            try {
              print('Attempting to update user_profiles for user ID: ${user.id}');
              print('Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}, Current Address: $_currentAddress');
              await Supabase.instance.client.from('user_profiles').update({
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
                'current_address': _currentAddress,
              }).eq('id', user.id);
              print('User profile updated successfully in Supabase.');
            } catch (e) {
              print('Error updating user profile in Supabase: $e');
            }
          } else if (user == null) {
            print('Supabase user is null, cannot update profile.');
          } else if (_currentAddress == null || _currentAddress!.isEmpty) {
            print('Current address is null or empty, skipping Supabase update.');
          }
        }
        print('Current Location: Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}, Accuracy: ${position.accuracy}m');
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0); // Move map to current location and set zoom
      await _fetchBusinessProfiles(radius: _searchRadius);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Could not get your location: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusinessProfiles({double? radius}) async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .eq('status', 'approved');

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
             
              final averageRating = await _getAverageRating(business['id']);
              business['average_rating'] = averageRating; 
              filteredProfiles.add(business);
            }
          }
        }
      }

      setState(() {
        _businessProfiles = filteredProfiles;
      
      });
    } catch (e) {
      setState(() {
        _locationPermissionMessage = "Error fetching business profiles: $e";
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; 
  }

  Future<double> _getAverageRating(String businessId) async {
    try {
      final response = await Supabase.instance.client
          .from('feedback')
          .select('rating')
          .eq('business_id', businessId)
          .eq('feedback_type', 'user');

      if (response.isEmpty) {
        return 0.0;
      }

      double totalRating = 0;
      for (var feedback in response) {
        totalRating += (feedback['rating'] as int).toDouble();
      }
      return totalRating / response.length;
    } catch (e) {
      print('Error fetching average rating for business $businessId: $e');
      return 0.0;
    }
  }

  void _onTapBusinessMarker(Map<String, dynamic> businessData) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SingleChildScrollView( 
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (businessData['cover_photo_url'] != null && businessData['cover_photo_url'].isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      businessData['cover_photo_url'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                if (businessData['cover_photo_url'] != null && businessData['cover_photo_url'].isNotEmpty)
                  const SizedBox(height: 16),
                Text(
                  businessData['business_name'] ?? 'Unknown Business',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessData['business_address'] ?? 'No address provided', 
                      style: const TextStyle(color: Colors.black),
                    ),
                    if (businessData['average_rating'] != null && businessData['average_rating'] > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${businessData['average_rating'].toStringAsFixed(1)}/5.0',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (businessData['services_offered'] != null && (businessData['services_offered'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services:',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0, 
                        runSpacing: 4.0, 
                        children: (businessData['services_offered'] as List).map((service) {
                          IconData iconData;
                          Color iconColor = Colors.blueGrey;

                          switch (service.toLowerCase()) {
                            case 'wash':
                              iconData = Icons.local_laundry_service;
                              break;
                            case 'dry':
                              iconData = Icons.dry_cleaning;
                              break;
                            case 'fold':
                              iconData = Icons.folder_special; 
                              break;
                            case 'iron':
                              iconData = Icons.iron;
                              break;
                            case 'delivery':
                              iconData = Icons.delivery_dining;
                              break;
                            default:
                              iconData = Icons.help_outline; 
                          }
                          return Chip(
                            avatar: Icon(iconData, color: iconColor, size: 18),
                            label: Text(service, style: const TextStyle(color: Colors.black)),
                            backgroundColor: Colors.grey[200],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
               
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
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
          ), 
        ); 
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF5A35E3),
        appBar: AppBar(
          title: const Text('Laundry Scout'),
          centerTitle: true,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentPosition == null
                ? LocationPermissionOverlay(
                    message: _locationPermissionMessage,
                    onRequestPermission: _requestLocationPermission,
                    selectedMapType: _selectedMapType,
                  )
                : Stack(
                    children: [
                      FlutterMap(
                          key: ValueKey(_currentPosition),
                          mapController: _mapController,
                          options: MapOptions(
                            center: _currentPosition != null
                                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                : LatLng(12.8797, 121.7740),
                            zoom: _currentPosition != null ? 16.0 : 6.0,
                            minZoom: 5.0,
                            maxZoom: 20.0,
                            initialZoom: _currentPosition != null ? 16.0 : 6.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _getTileLayerUrlTemplate(_selectedMapType),
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            if (_currentPosition != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    useRadiusInMeter: true,
                                    radius: _searchRadius * 1000,
                                    color: const Color(0xFF5A35E3).withOpacity(0.2),
                                    borderColor: const Color(0xFF5A35E3),
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                if (_currentPosition != null)
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
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              'lib/assets/official.png',
                                              width: 40.0,
                                              height: 40.0,
                                            ),
                                            if (business['average_rating'] != null && business['average_rating'] > 0)
                                            Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                  business['average_rating'].toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
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
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF5A35E3), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Location',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentAddress != null && _currentAddress!.isNotEmpty ? _currentAddress! : 'No Current Address',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A35E3).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<MapType>(
                            value: _selectedMapType,
                            dropdownColor: const Color(0xFF5A35E3).withOpacity(0.9),
                            icon: const Icon(Icons.map, color: Colors.white),
                            onChanged: _onMapTypeChanged,
                            items: const [
                              DropdownMenuItem(
                                value: MapType.defaultMap,
                                child: Text('Default', style: TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: MapType.satellite,
                                child: Text('Satellite', style: TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: MapType.terrain,
                                child: Text('Terrain', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Slider(
                                value: _searchRadius,
                                min: 0.5,
                                max: 10.0,
                                divisions: 19,
                                label: _searchRadius.toStringAsFixed(1),
                                onChanged: _onSearchRadiusChanged,
                                activeColor: const Color(0xFF5A35E3),
                                inactiveColor: const Color(0xFF5A35E3).withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      );
    }

  void _onSearchRadiusChanged(double newRadius) {
    setState(() {
      _searchRadius = newRadius;
    });
    _fetchBusinessProfiles(radius: _searchRadius);
  }
}