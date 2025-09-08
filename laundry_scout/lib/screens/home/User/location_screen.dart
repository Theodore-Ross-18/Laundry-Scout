import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../utils/network_speed_detector.dart';
import '../../../utils/location_cache.dart';
import '../../../services/places_service.dart';
import '../../../utils/distance_calculator.dart' as utils;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  MapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _registeredShops = [];
  List<Map<String, dynamic>> _unregisteredShops = [];
  String _currentLocationText = 'Getting location...';
  
  // Network optimization variables
  NetworkSpeed _networkSpeed = NetworkSpeed.unknown;
  LoadingStrategy? _loadingStrategy;
  bool _isLoadingProgressively = false;
  String _loadingStatus = 'Detecting network speed...';
  Timer? _progressiveLoadingTimer;

  @override
  void initState() {
    super.initState();
    _initializeWithNetworkDetection();
  }
  
  @override
  void dispose() {
    _progressiveLoadingTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeWithNetworkDetection() async {
    setState(() {
      _loadingStatus = 'Detecting network speed...';
    });
    
    // Detect network speed first
    _networkSpeed = await NetworkSpeedDetector.instance.detectSpeed();
    _loadingStrategy = NetworkSpeedDetector.instance.getLoadingStrategy();
    
    setState(() {
      _loadingStatus = 'Network: ${_networkSpeed.name.toUpperCase()}';
    });
    
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
        
        return address.isNotEmpty ? address : 'Location found';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Location found';
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
            content: Text('Location permission is required to find nearby laundry shops'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('DEBUG: _getCurrentLocation called');
      setState(() {
        _loadingStatus = 'Checking cached location...';
      });
      
      // Try to get cached location first
      Position? position = await LocationCache.instance.getCachedUserLocation();
      print('DEBUG: Cached position: $position');
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _loadingStatus = 'Getting address...';
        });
        
        // Get actual address from cached coordinates
        String address = await _getAddressFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        setState(() {
          _currentLocationText = address;
          _loadingStatus = 'Using cached location';
        });
        await _loadNearbyLaundryShops();
        return;
      }
      
      setState(() {
        _loadingStatus = 'Getting GPS location...';
      });
      
      print('DEBUG: Attempting to get GPS location');
      // Get GPS accuracy based on network speed
      LocationAccuracy accuracy = LocationAccuracy.medium;
      if (_loadingStrategy != null) {
        switch (_loadingStrategy!.gpsAccuracy) {
          case 'low':
            accuracy = LocationAccuracy.low;
            break;
          case 'medium':
            accuracy = LocationAccuracy.medium;
            break;
          case 'high':
            accuracy = LocationAccuracy.high;
            break;
        }
      }
      
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      ).timeout(
        Duration(milliseconds: _loadingStrategy?.timeoutMs ?? 10000),
        onTimeout: () async {
          // Fallback to lower accuracy on timeout
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
        },
      );
      
      // Cache the new location
      await LocationCache.instance.cacheUserLocation(position);
      
      setState(() {
        _currentPosition = position;
        _loadingStatus = 'Getting address...';
      });
      
      // Get actual address from GPS coordinates
      String address = await _getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      setState(() {
        _currentLocationText = address;
        _loadingStatus = 'Location acquired';
        _isLoading = false;
      });
      
      await _loadNearbyLaundryShops();
    } catch (e) {
      print('DEBUG: Error in _getCurrentLocation: $e');
      setState(() {
        _isLoading = false;
        _currentLocationText = 'Unable to get location';
        _loadingStatus = 'Location error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchNearbyLaundryShops() async {
    if (_currentPosition == null) {
      print('DEBUG: No current position available');
      return;
    }

    try {
      print('DEBUG: Starting search at lat: ${_currentPosition!.latitude}, lon: ${_currentPosition!.longitude}');
      setState(() {
        _loadingStatus = 'Searching for nearby laundry shops...';
      });
      
      const double radiusMeters = 5000; // 5km radius
      
      // Fetch registered shops from database
      setState(() {
        _loadingStatus = 'Loading registered shops...';
      });
      
      final registeredShopsResponse = await Supabase.instance.client
          .from('registered_shops')
          .select('*')
          .eq('is_active', true)
          .eq('is_verified', true);
      
      List<Map<String, dynamic>> registeredShops = List<Map<String, dynamic>>.from(registeredShopsResponse);
      
      // Filter registered shops by distance
        registeredShops = utils.LaundryDistanceUtils.filterShopsWithinRadius(
          registeredShops,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          radiusMeters,
        );
      
      print('DEBUG: Found ${registeredShops.length} registered shops within radius');
      
      // Fetch unregistered shops using OpenStreetMap
      setState(() {
        _loadingStatus = 'Searching for unregistered shops...';
      });
      
      final nearbyShops = await PlacesService.searchLaundryShops(
         latitude: _currentPosition!.latitude,
         longitude: _currentPosition!.longitude,
         radiusMeters: radiusMeters,
       );
       
       // If no shops found with Overpass API, try text search as fallback
       List<Map<String, dynamic>> unregisteredShops = List.from(nearbyShops);
       if (unregisteredShops.isEmpty) {
         print('DEBUG: No shops found with Overpass API, trying text search fallback');
         final textSearchResults = await PlacesService.searchByText(
           query: 'laundromat laundry dry cleaning',
           latitude: _currentPosition!.latitude,
           longitude: _currentPosition!.longitude,
           radiusKm: radiusMeters / 1000,
         );
         unregisteredShops.addAll(textSearchResults);
         print('DEBUG: Text search found ${textSearchResults.length} additional shops');
       }
       
       // Apply distance filtering to unregistered shops
        unregisteredShops = utils.LaundryDistanceUtils.filterShopsWithinRadius(
          unregisteredShops,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          radiusMeters,
        );
      
      print('DEBUG: Found ${unregisteredShops.length} unregistered shops within radius (${nearbyShops.length} from Overpass, ${unregisteredShops.length - nearbyShops.length} from text search)');
      print('DEBUG: Total shops: ${registeredShops.length + unregisteredShops.length} (${registeredShops.length} registered, ${unregisteredShops.length} unregistered)');
      
      setState(() {
        _registeredShops = registeredShops;
        _unregisteredShops = unregisteredShops;
        _loadingStatus = 'Found ${registeredShops.length + unregisteredShops.length} laundry shops nearby';
      });
      
      // Update markers to show the new shops
      _createMarkers();
      
      // Store fetched unregistered shops in database for future reference
      await _storeUnregisteredShops(unregisteredShops);
      
    } catch (e) {
       print('DEBUG: Error in _fetchNearbyLaundryShops: $e');
       setState(() {
         _loadingStatus = 'Error finding laundry shops: $e';
       });
     }
   }

   Future<void> _storeUnregisteredShops(List<Map<String, dynamic>> shops) async {
    try {
      final supabase = Supabase.instance.client;
      
      for (var shop in shops) {
        // Check if shop already exists to prevent duplicates based on location
        final existingShop = await supabase
            .from('unregistered_shops')
            .select('id')
            .eq('business_name', shop['business_name'])
            .eq('latitude', shop['latitude'])
            .eq('longitude', shop['longitude'])
            .maybeSingle();
        
        if (existingShop == null) {
          // Insert new unregistered shop with updated schema
          await supabase.from('unregistered_shops').insert({
            'business_name': shop['business_name'],
            'latitude': shop['latitude'],
            'longitude': shop['longitude'],
            'exact_location': shop['exact_location'],
            'phone_number': shop['phone'],
            'description': shop['description'] ?? 'Laundry service discovered via map search',
          });
        }
      }
    } catch (e) {
      // Error storing shops, but don't show to user as it's not critical
      print('Error storing unregistered shops: $e');
    }
  }

  Future<void> _loadNearbyLaundryShops() async {
    if (_currentPosition == null) return;

    try {
      setState(() {
        _loadingStatus = 'Checking cached businesses...';
      });
      
      // Try to get cached business data first
      List<Map<String, dynamic>>? cachedBusinesses = await LocationCache.instance
          .getCachedBusinessProfiles(_currentPosition!);
      
      if (cachedBusinesses != null && _loadingStrategy?.enableCaching == true) {
        setState(() {
          _registeredShops = cachedBusinesses;
          _loadingStatus = 'Using cached data';
        });
        
        // Add mock unregistered shops
        _addMockUnregisteredShops();
        
        if (_loadingStrategy?.enableProgressiveLoading == true) {
          await _createMarkersProgressively();
        } else {
          _createMarkers();
        }
        return;
      }
      
      setState(() {
        _loadingStatus = 'Loading businesses...';
      });
      
      // Load registered laundry shops with fallback strategy
      final double radiusKm = _networkSpeed == NetworkSpeed.slow ? 2.0 : 
                             _networkSpeed == NetworkSpeed.medium ? 5.0 : 10.0;
      
      List<Map<String, dynamic>> allBusinesses;
      
      try {
        // Try optimized spatial query first
        // Ensure limit is valid (PostgreSQL requires limit >= 0)
        final limitCount = _loadingStrategy?.maxMarkersInitial ?? 50;
        final validLimit = limitCount < 0 ? 1000 : limitCount; // Use 1000 for "load all"
        
        final registeredResponse = await Supabase.instance.client
            .rpc('get_nearby_businesses', params: {
              'user_lat': _currentPosition!.latitude,
              'user_lng': _currentPosition!.longitude,
              'radius_km': radiusKm,
              'limit_count': validLimit
            })
            .timeout(
              Duration(milliseconds: _loadingStrategy?.timeoutMs ?? 10000),
            );
        
        allBusinesses = List<Map<String, dynamic>>.from(registeredResponse);
      } catch (e) {
        // Fallback to basic query if RPC function doesn't exist
        print('RPC function not available, using fallback query: $e');
        setState(() {
          _loadingStatus = 'Using fallback query...';
        });
        
        // Ensure limit is valid for fallback query too
        final fallbackLimit = _loadingStrategy?.maxMarkersInitial ?? 50;
        final validFallbackLimit = fallbackLimit < 0 ? 1000 : fallbackLimit;
        
        final response = await Supabase.instance.client
            .from('business_profiles')
            .select('id, business_name, exact_location, latitude, longitude, cover_photo_url, does_delivery, availability_status')
            .not('latitude', 'is', null)
            .not('longitude', 'is', null)
            .limit(validFallbackLimit);
            
        allBusinesses = List<Map<String, dynamic>>.from(response);
      }
      
      // Cache the business data
      if (_loadingStrategy?.enableCaching == true) {
        await LocationCache.instance.cacheBusinessProfiles(allBusinesses, _currentPosition!);
      }
      
      setState(() {
        _registeredShops = allBusinesses;
        _loadingStatus = 'Businesses loaded';
      });

      // Add mock unregistered shops
      _addMockUnregisteredShops();

      // Create markers based on loading strategy
      if (_loadingStrategy?.enableProgressiveLoading == true) {
        await _createMarkersProgressively();
      } else {
        _createMarkers();
      }
    } catch (e) {
      setState(() {
        _loadingStatus = 'Error loading data';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading laundry shops: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Fallback: try to show any cached data even if expired
      final fallbackData = await LocationCache.instance
          .getCachedBusinessProfiles(_currentPosition!, maxDistanceKm: 10.0);
      if (fallbackData != null) {
        setState(() {
          _registeredShops = fallbackData;
          _loadingStatus = 'Using offline data';
        });
        _addMockUnregisteredShops();
        _createMarkers();
      }
    }
  }
  
  void _addMockUnregisteredShops() {
    // Removed static mock data - only show real OpenStreetMap results
    _unregisteredShops = [];
  }

  void _createMarkers() {
    List<Marker> markers = [];

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }

    // Limit markers based on loading strategy
    int maxMarkers = _loadingStrategy?.maxMarkersInitial ?? -1;
    List<Map<String, dynamic>> limitedRegisteredShops = maxMarkers > 0 
        ? _registeredShops.take(maxMarkers).toList() 
        : _registeredShops;

    // Add registered laundry shop markers (green)
    for (var shop in limitedRegisteredShops) {
      if (shop['latitude'] != null && shop['longitude'] != null) {
        markers.add(
          Marker(
            point: LatLng(shop['latitude'], shop['longitude']),
            child: GestureDetector(
              onTap: () => _showShopDetails(shop, true),
              child: const Icon(
                Icons.local_laundry_service,
                color: Colors.green,
                size: 30,
              ),
            ),
          ),
        );
      }
    }

    // Add unregistered laundry shop markers (red) - limit for slow connections
    List<Map<String, dynamic>> limitedUnregisteredShops = _networkSpeed == NetworkSpeed.slow 
        ? _unregisteredShops.take(2).toList() 
        : _unregisteredShops;
        
    for (var shop in limitedUnregisteredShops) {
      markers.add(
        Marker(
          point: LatLng(shop['latitude'], shop['longitude']),
          child: GestureDetector(
            onTap: () => _showShopDetails(shop, false),
            child: const Icon(
              Icons.local_laundry_service,
              color: Colors.red,
              size: 30,
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }
  
  Future<void> _createMarkersProgressively() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _isLoadingProgressively = true;
      _loadingStatus = 'Loading markers progressively...';
    });
    
    List<Marker> markers = [];
    
    // Always add current location marker first
    markers.add(
      Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );
    
    setState(() {
      _markers = markers;
    });
    
    // Progressive loading delay based on network speed
    int delayMs = _networkSpeed == NetworkSpeed.slow ? 800 : 
                  _networkSpeed == NetworkSpeed.medium ? 400 : 200;
    
    // Add registered shops progressively
    for (int i = 0; i < _registeredShops.length; i++) {
      final shop = _registeredShops[i];
      if (shop['latitude'] != null && shop['longitude'] != null) {
        markers.add(
          Marker(
            point: LatLng(shop['latitude'], shop['longitude']),
            child: GestureDetector(
              onTap: () => _showShopDetails(shop, true),
              child: const Icon(
                Icons.local_laundry_service,
                color: Colors.green,
                size: 30,
              ),
            ),
          ),
        );
        
        setState(() {
          _markers = List.from(markers);
          _loadingStatus = 'Loaded ${markers.length - 1} businesses...';
        });
        
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    
    // Add unregistered shops progressively
    for (var shop in _unregisteredShops) {
      markers.add(
        Marker(
          point: LatLng(shop['latitude'], shop['longitude']),
          child: GestureDetector(
            onTap: () => _showShopDetails(shop, false),
            child: const Icon(
              Icons.local_laundry_service,
              color: Colors.red,
              size: 30,
            ),
          ),
        ),
      );
      
      setState(() {
        _markers = List.from(markers);
        _loadingStatus = 'Loaded ${markers.length - 1} businesses...';
      });
      
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    
    setState(() {
      _isLoadingProgressively = false;
      _loadingStatus = 'All markers loaded';
    });
  }

  // Helper methods for network status display
  IconData _getNetworkIcon() {
    switch (_networkSpeed) {
      case NetworkSpeed.fast:
        return Icons.wifi;
      case NetworkSpeed.medium:
        return Icons.wifi;
      case NetworkSpeed.slow:
        return Icons.network_wifi;
      case NetworkSpeed.unknown:
        return Icons.wifi_off;
    }
  }

  Color _getNetworkColor() {
    switch (_networkSpeed) {
      case NetworkSpeed.fast:
        return Colors.green;
      case NetworkSpeed.medium:
        return Colors.yellow;
      case NetworkSpeed.slow:
        return Colors.orange;
      case NetworkSpeed.unknown:
        return Colors.red;
    }
  }

  String _getNetworkSpeedText() {
    switch (_networkSpeed) {
      case NetworkSpeed.fast:
        return 'Fast connection';
      case NetworkSpeed.medium:
        return 'Good connection';
      case NetworkSpeed.slow:
        return 'Slow connection';
      case NetworkSpeed.unknown:
        return 'No connection';
    }
  }

  void _showShopDetails(Map<String, dynamic> shop, bool isRegistered) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRegistered ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isRegistered ? 'REGISTERED' : 'UNREGISTERED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ]
              ),
              const SizedBox(height: 16),
              Text(
                shop['business_name'] ?? 'Unknown Laundry',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shop['exact_location'] ?? 'Location not available',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isRegistered) ...[
                const Text(
                  'Features:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.message, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Text('Can communicate through app'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(shop['does_delivery'] == true ? 'Delivery available' : 'No delivery'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      shop['availability_status'] == 'open' ? Icons.check_circle : Icons.cancel,
                      color: shop['availability_status'] == 'open' ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(shop['availability_status'] == 'open' ? 'Currently open' : 'Currently closed'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to business detail or message screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact Laundry',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Unregistered Laundry',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This laundry shop is not registered with our app. You can view their location but cannot communicate through the app.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                  ),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : !_locationPermissionGranted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Location Permission Required',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'We need access to your location to show nearby laundry shops and provide better service.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requestLocationPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Allow Location Access',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header with location info
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Laundry Scout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Your Location',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _currentLocationText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_loadingStatus.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getNetworkIcon(),
                                          color: _getNetworkColor(),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getNetworkSpeedText(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (_loadingStatus.isNotEmpty)
                                                Text(
                                                  _loadingStatus,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (_isLoadingProgressively)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Map and locate button
                    Expanded(
                      child: Stack(
                        children: [
                          // Map
                          _currentPosition != null
                              ? FlutterMap(
                                  mapController: _mapController ??= MapController(),
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    initialZoom: 15,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.laundry_scout',
                                    ),
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: LatLng(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                          ),
                                          radius: 1000, // 1km radius for testing
                                          useRadiusInMeter: true,
                                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                          borderColor: const Color(0xFF6C63FF),
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                    MarkerLayer(
                                      markers: _markers,
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Text('Unable to load map'),
                                ),
                          // Legend
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Legend',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('You', style: TextStyle(fontSize: 10, color: Colors.black)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Registered', style: TextStyle(fontSize: 10, color: Colors.black)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Unregistered', style: TextStyle(fontSize: 10, color: Colors.black)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C63FF),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('1km Range', style: TextStyle(fontSize: 10, color: Colors.black)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Locate Laundry Button
                          Positioned(
                            bottom: 30,
                            left: 20,
                            right: 20,
                            child: ElevatedButton(
                              onPressed: () async {
                                print('DEBUG: Locate button pressed');
                                print('DEBUG: _currentPosition = $_currentPosition');
                                print('DEBUG: _mapController = $_mapController');
                                
                                if (_currentPosition != null && _mapController != null) {
                                  print('DEBUG: Moving map and fetching shops');
                                  // Move map to current location
                                  _mapController!.move(
                                    LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    16,
                                  );
                                  
                                  // Fetch and display nearby laundry shops
                                  await _fetchNearbyLaundryShops();
                                } else {
                                  print('DEBUG: Cannot locate - missing position or map controller');
                                  // Try to get location if not available
                                  await _getCurrentLocation();
                                  
                                  // If still no location (common on web), use a test location
                                  if (_currentPosition == null) {
                                    print('DEBUG: Using fallback test location');
                                    setState(() {
                                      // Using New York City as test location
                                      _currentPosition = Position(
                                        latitude: 40.7128,
                                        longitude: -74.0060,
                                        timestamp: DateTime.now(),
                                        accuracy: 0,
                                        altitude: 0,
                                        altitudeAccuracy: 0,
                                        heading: 0,
                                        headingAccuracy: 0,
                                        speed: 0,
                                        speedAccuracy: 0,
                                      );
                                      _currentLocationText = 'Test Location (NYC)';
                                    });
                                    
                                    if (_mapController != null) {
                                      _mapController!.move(
                                        LatLng(40.7128, -74.0060),
                                        16,
                                      );
                                    }
                                    
                                    // Now fetch laundry shops
                                    await _fetchNearbyLaundryShops();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Locate Laundry',
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
    );
  }
}