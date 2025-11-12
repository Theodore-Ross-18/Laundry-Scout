// ignore_for_file: unnecessary_null_comparison, unused_element

import 'dart:ui';
import 'package:flutter/scheduler.dart';
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
  
  // Address editing state variables
  bool _isEditingAddress = false;
  final TextEditingController _addressController = TextEditingController();
  ScrollController? _scrollController; 

  // Helper method to format long addresses for better display
  String _formatAddressForDisplay(String? address) {
    if (address == null || address.isEmpty) {
      return 'No Current Address Yet\nTap Here';
    }
    
    // If address is already short enough for 2 lines, return as is
    if (address.length <= 50) {
      return address;
    }
    
    // For very long addresses, try to split at natural break points
    // First try to split at comma
    int commaIndex = address.indexOf(',');
    if (commaIndex != -1 && commaIndex < address.length - 1) {
      String firstPart = address.substring(0, commaIndex).trim();
      String secondPart = address.substring(commaIndex + 1).trim();
      
      // If first part is still too long, truncate it
      if (firstPart.length > 30) {
        firstPart = '${firstPart.substring(0, 27)}...';
      }
      
      // If second part is too long, truncate it
      if (secondPart.length > 30) {
        secondPart = '${secondPart.substring(0, 27)}...';
      }
      
      return '$firstPart,\n$secondPart';
    }
    
    // If no comma found, split at word boundary around 25 characters
    int splitPoint = 25;
    if (address.length > splitPoint) {
      // Find the last space before splitPoint
      int lastSpace = address.lastIndexOf(' ', splitPoint);
      if (lastSpace != -1) {
        String firstPart = address.substring(0, lastSpace).trim();
        String secondPart = address.substring(lastSpace + 1).trim();
        
        // Truncate second part if too long
        if (secondPart.length > 25) {
          secondPart = '${secondPart.substring(0, 22)}...';
        }
        
        return '$firstPart\n$secondPart';
      }
    }
    
    // Fallback: just truncate and add ellipsis
    return '${address.substring(0, 47)}...';
  }


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

  @override
  void dispose() {
    _addressController.dispose();
    _scrollController?.dispose();
    super.dispose();
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
      final user = Supabase.instance.client.auth.currentUser;
      String? fetchedAddressFromProfile;

      if (user != null) {
        try {
          final response = await Supabase.instance.client
              .from('user_profiles')
              .select('current_address')
              .eq('id', user.id)
              .single();
          if (response.isNotEmpty && response['current_address'] != null) {
            fetchedAddressFromProfile = response['current_address'] as String;
            setState(() {
              _currentAddress = fetchedAddressFromProfile;
            });
            print('Fetched address from user profile: $_currentAddress');
          }
        } catch (e) {
          print('Error fetching address from user profile: $e');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
      });
      print('Current Position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

      // Always update Supabase with the latest coordinates
      if (user != null && _currentPosition != null) {
        try {
          await Supabase.instance.client.from('user_profiles').update({
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
          }).eq('id', user.id);
          print('Supabase user profile coordinates updated successfully.');
        } catch (e) {
          print('Error updating user profile coordinates: $e');
        }
      }

      // If no address was fetched from profile, try geocoding
      if (_currentAddress == null || _currentAddress!.isEmpty) {
        try {
          if (_currentPosition == null) {
            print('Current position is null, cannot perform geocoding.');
            setState(() {
              _currentAddress = "No current address yet";
            });
          } else {
            print('Geocoding coordinates: Latitude: ${_currentPosition?.latitude}, Longitude: ${_currentPosition?.longitude}');
            List<geocoding.Placemark>? placemarks = await geocoding.placemarkFromCoordinates(
                _currentPosition!.latitude,
                _currentPosition!.longitude
            );
            print('Geocoding placemarks result: $placemarks');

            if (placemarks != null && placemarks.isNotEmpty && placemarks[0] != null) {
              geocoding.Placemark place = placemarks[0];
              String address = "";

              // Build address from available placemark fields
              if (place.street != null && place.street!.isNotEmpty) {
                address += place.street!;
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                if (address.isNotEmpty) address += ", ";
                address += place.locality!;
              }
              if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                if (address.isNotEmpty) address += ", ";
                address += place.administrativeArea!;
              }

              setState(() {
                _currentAddress = address.isNotEmpty ? address : "Location detected but address unavailable";
              });
              print('Constructed Address: $_currentAddress');
            } else {
              setState(() {
                _currentAddress = "No current address yet";
              });
              print('No placemarks found for the current position.');
            }
          }
        } catch (e, stackTrace) {
          print('Error during geocoding: $e\nStackTrace: $stackTrace');
          setState(() {
            _currentAddress = "Geocoding failed: $e";
          });
        }
      }

      // Update current_address in Supabase if it was determined
      if (user != null && _currentAddress != null && _currentAddress!.isNotEmpty) {
        try {
          await Supabase.instance.client.from('user_profiles').update({
            'current_address': _currentAddress,
          }).eq('id', user.id);
          print('Supabase user profile address updated successfully.');
        } catch (e) {
          print('Error updating user profile address: $e');
        }
      } else if (user == null) {
        print('Supabase user is null, cannot update profile address.');
      } else if (_currentAddress == null || _currentAddress!.isEmpty) {
        print('Current address is null or empty, cannot update profile address.');
      }

      await _fetchBusinessProfiles(radius: _searchRadius);
      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null) {
          _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0);
        }
      });
    } catch (e) {
      print('Error getting current location: $e');
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
                        right: 100, // Added to constrain width
                        child: GestureDetector(
                          onTap: _showAddressEditSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFF5E35E3), size: 20),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatAddressForDisplay(_currentAddress),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 17,
                        right: 1,
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

  // Address editing methods
  void _toggleAddressEdit() {
    setState(() {
      _isEditingAddress = !_isEditingAddress;
      if (!_isEditingAddress) {
        _currentAddress = _addressController.text;
      }
    });
  }

  Future<void> _saveAddressToSupabase() async {
    final addressToSave = _addressController.text.trim();
    if (addressToSave.isNotEmpty) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('user_profiles')
              .update({'current_address': addressToSave})
              .eq('id', user.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address updated successfully!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating address: $e')),
          );
        }
      }
    }
  }

  void _showAddressEditSheet() {
    _addressController.text = _currentAddress ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          builder: (BuildContext context, ScrollController scrollController) {
            _scrollController = scrollController;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Edit Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A35E3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAddressEditField(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Update the current address with the text from controller
                              setState(() {
                                _currentAddress = _addressController.text;
                              });
                              // Save to Supabase
                              await _saveAddressToSupabase();
                              // Close the bottom sheet
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A35E3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save Address'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddressEditField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5A35E3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_outlined, color: Color(0xFF5A35E3), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _addressController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your address',
                    hintStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}