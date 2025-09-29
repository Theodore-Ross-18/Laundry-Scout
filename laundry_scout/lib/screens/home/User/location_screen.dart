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
import '../../../utils/distance_calculator.dart' as utils;
// Remove url_launcher import as it's not needed
// import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double _currentRadiusKm = 1.0; // Make currentRadiusKm a class-level variable
  MapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _allShops = []; // Renamed from _registeredShops
  // List<Map<String, dynamic>> _unregisteredShops = []; // Removed
  String _currentLocationText = 'Getting location...';
  
  // Error handling variables
  bool _hasError = false;
  String _errorMessage = '';
  
  // Network optimization variables
  NetworkSpeed _networkSpeed = NetworkSpeed.unknown;
  LoadingStrategy? _loadingStrategy;
  bool _isLoadingProgressively = false;
  String _loadingStatus = 'Detecting network speed...';
  Timer? _progressiveLoadingTimer;

  @override
  void initState() {
    super.initState();
    // _currentRadiusKm = 1.0; // Removed redundant initialization
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
    
    // Pre-cache location data if network allows
    await _preCacheLocationData();
    
    await _checkLocationPermission();
  }

  Future<void> _preCacheLocationData() async {
    if (_loadingStrategy?.enableCaching != true) return;
    
    try {
      // Pre-load basic business data in background
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id,
            business_name,
            latitude,
            longitude,
            address,
            phone_number,
            services_offered,
            service_prices,
            rating
          ''')
          .eq('is_laundry_service', true)
          .limit(50)
          .timeout(const Duration(seconds: 3));
          
      final businesses = List<Map<String, dynamic>>.from(response);
      
      // Cache for future use
      if (_currentPosition != null) {
        await LocationCache.instance.cacheBusinessProfiles(businesses, _currentPosition!);
      }
      
    } catch (e) {
      debugPrint('Pre-caching failed: $e');
    }
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
      debugPrint('Error getting address: $e');
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

  Future<void> _retryLoading() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
      _loadingStatus = 'Retrying...';
    });
    
    await _initializeWithNetworkDetection();
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('_getCurrentLocation called');
      setState(() {
        _loadingStatus = 'Checking cached location...';
        _hasError = false;
        _errorMessage = '';
      });
      
      // Try to get cached location first
      Position? position = await LocationCache.instance.getCachedUserLocation();
      debugPrint('Cached position: $position');
      
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
          _loadingStatus = 'Loading nearby shops...';
        });
        
        await _loadNearbyLaundryShops();
        return;
      }
      
      setState(() {
        _loadingStatus = 'Getting GPS location...';
      });
      
      debugPrint('Attempting to get GPS location');
      // Get GPS accuracy based on network speed
      LocationAccuracy accuracy = LocationAccuracy.high; // Always request high accuracy
      // if (_loadingStrategy != null) {
      //   accuracy = _loadingStrategy!.gpsAccuracy == 'high' 
      //       ? LocationAccuracy.high 
      //       : _loadingStrategy!.gpsAccuracy == 'low'
      //           ? LocationAccuracy.low
      //           : LocationAccuracy.medium;
      // }
      
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint('Got GPS position: ${newPosition.latitude}, ${newPosition.longitude}');
      
      setState(() {
        _currentPosition = newPosition;
        _loadingStatus = 'Getting address with high accuracy...'; // Updated status
      });
      
      // Cache the location
      await LocationCache.instance.cacheUserLocation(newPosition);
      
      String address = await _getAddressFromCoordinates(
        newPosition.latitude, 
        newPosition.longitude
      );
      
      setState(() {
        _currentLocationText = address;
        _loadingStatus = 'Location updated';
        _isLoading = false;
      });
      
      await _loadNearbyLaundryShops();
      
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





  Future<void> _loadNearbyLaundryShops() async {
    if (_currentPosition == null) {
      debugPrint('[_loadNearbyLaundryShops] _currentPosition is null, returning.');
      return;
    }

    _currentRadiusKm = 1.0; // Reset radius for a new search

    // setState(() {
    //   _displayedRadiusKm = 1.0; // Reset displayed radius
    // });

    try {
      debugPrint('[_loadNearbyLaundryShops] Starting to load nearby laundry shops.');
      setState(() {
        _loadingStatus = 'Loading shops...';
        _hasError = false;
        _errorMessage = '';
      });

      // Try cached data first
      final cachedShops = await LocationCache.instance.getCachedBusinessProfiles(_currentPosition!);
      if (cachedShops != null && cachedShops.isNotEmpty) {
        debugPrint('[_loadNearbyLaundryShops] Loaded ${cachedShops.length} shops from cache.');
        setState(() {
          _allShops = cachedShops;
          _loadingStatus = 'Loaded cached data.';
        });
        
        // Load basic markers from cached data
        await _fetchNearbyLaundryShops();
        
        // Background refresh
        await _loadFreshDataInBackground();
        // Continue to network-optimized loading to ensure radius increment logic is always applied
      }

      // Network-optimized loading
      // debugPrint('[_loadNearbyLaundryShops] Calling _loadBusinessesNetworkOptimized.');
      await _loadBusinessesNetworkOptimized();
      // debugPrint('[_loadNearbyLaundryShops] _loadBusinessesNetworkOptimized completed.');

    } catch (e) {
      debugPrint('[_loadNearbyLaundryShops] Error loading laundry shops: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to load nearby laundry shops. Please check your internet connection.';
        _isLoading = false;
      });
      
      // Try to load from cache even if old
      try {
        debugPrint('[_loadNearbyLaundryShops] Attempting fallback cache loading.');
        final fallbackShops = await LocationCache.instance.getCachedBusinessProfiles(_currentPosition!);
        if (fallbackShops != null && fallbackShops.isNotEmpty) {
          debugPrint('[_loadNearbyLaundryShops] Loaded ${fallbackShops.length} shops from fallback cache.');
          setState(() {
            _allShops = fallbackShops;
            _hasError = false;
            _isLoading = false;
          });
          await _fetchNearbyLaundryShops();
        } else {
          debugPrint('[_loadNearbyLaundryShops] Fallback cache is empty.');
        }
      } catch (fallbackError) {
        debugPrint('[_loadNearbyLaundryShops] Fallback cache loading also failed: $fallbackError');
      }
    }
  }

  Future<void> _loadBusinessesNetworkOptimized() async {
    // debugPrint('[_loadBusinessesNetworkOptimized] Initial currentRadiusKm: $currentRadiusKm');
    List<Map<String, dynamic>> businesses = [];
    // double currentRadiusKm = 1.0; // Removed local variable
    const double maxRadiusKm = 5.0; // Max radius as requested

    debugPrint('[_loadBusinessesNetworkOptimized] Initial _currentRadiusKm: $_currentRadiusKm');
    try {
      while (businesses.isEmpty && _currentRadiusKm <= maxRadiusKm) {
        debugPrint('[_loadBusinessesNetworkOptimized] Inside while loop. _currentRadiusKm: $_currentRadiusKm');
        setState(() {
          _loadingStatus = 'Searching within ${_currentRadiusKm.toInt()}km radius...';
        });

        // Use lightweight query for initial load with current radius
        final response = await Supabase.instance.client
            .from('business_profiles')
            .select(
                'id, business_name, business_address, latitude, longitude, cover_photo_url, services_offered, rating, total_reviews')
            .eq('is_laundry_service', true)
            // .limit(_loadingStrategy?.maxMarkersInitial ?? 20)
            .timeout(Duration(milliseconds: _loadingStrategy?.timeoutMs ?? 8000));

        List<Map<String, dynamic>> fetchedBusinesses = List<Map<String, dynamic>>.from(response);
        debugPrint('[_loadBusinessesNetworkOptimized] Fetched ${fetchedBusinesses.length} businesses from Supabase.');

        // Filter by _currentRadiusKm distance efficiently
        businesses = fetchedBusinesses.where((business) {
          if (business['latitude'] == null || business['longitude'] == null) return false;

          final distance = utils.LaundryDistanceUtils.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            business['latitude'],
            business['longitude'],
          );
          // debugPrint('[_loadBusinessesNetworkOptimized] Business: ${business['business_name']}, Distance: $distance km, _currentRadiusKm: $_currentRadiusKm');
          return distance <= _currentRadiusKm;
        }).toList();

        debugPrint('[_loadBusinessesNetworkOptimized] After distance filter. businesses.length: ${businesses.length}, businesses.isEmpty: ${businesses.isEmpty}');

        if (businesses.isEmpty) {
          _currentRadiusKm += 1.0; // Increment radius if no shops found
          debugPrint('[_loadBusinessesNetworkOptimized] Radius incremented to: $_currentRadiusKm');
        }
        // _displayedRadiusKm = _currentRadiusKm; // Update displayed radius - Removed as _currentRadiusKm is now the displayed radius
      }
      debugPrint('[_loadBusinessesNetworkOptimized] Exited while loop. Final _currentRadiusKm: $_currentRadiusKm');

      // Sort by distance
      businesses.sort((a, b) {
        final distanceA = utils.LaundryDistanceUtils.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a['latitude'],
          a['longitude'],
        );

        final distanceB = utils.LaundryDistanceUtils.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b['latitude'],
          b['longitude'],
        );

        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _allShops = businesses;
        if (businesses.isNotEmpty) {
          _loadingStatus = 'Loaded ${businesses.length} shops within ${_currentRadiusKm.toInt()}km';
        } else {
          _loadingStatus = 'No shops found within ${maxRadiusKm.toInt()}km.';
        }
        _isLoading = false; // Set _isLoading to false here
      });

      // Cache the results
      if (_loadingStrategy?.enableCaching == true) {
        await LocationCache.instance.cacheBusinessProfiles(
          businesses,
          _currentPosition!,
        );
      }

      // Create markers progressively
      await _fetchNearbyLaundryShops();

      // Load additional data in background
      _loadFreshDataInBackground();

    } catch (e) {
      debugPrint(
          '[_loadBusinessesNetworkOptimized] Network optimized loading failed: $e');
      // Fallback to basic loading if network optimized fails
      await _loadBusinessesBasic();
      if (businesses.isEmpty) {
        debugPrint('Basic loading failed: $e');
      }
    }
  }

  Future<void> _loadBusinessesBasic() async {
    try {
      List<Map<String, dynamic>> businesses = [];
      // double currentRadiusKm = 1.0; // Removed local variable
      const double maxRadiusKm = 5.0;

      while (businesses.isEmpty && _currentRadiusKm <= maxRadiusKm) {
        setState(() {
          _loadingStatus = 'Searching within ${_currentRadiusKm.toInt()}km radius...';
        });

        final response = await Supabase.instance.client
            .from('business_profiles')
            .select(
                'id, business_name, business_address, latitude, longitude, cover_photo_url, services_offered, rating, total_reviews')
            .eq('is_laundry_service', true)
            .limit(100);

        List<Map<String, dynamic>> fetchedBusinesses = List<Map<String, dynamic>>.from(response);

        // Apply distance filtering for the current radius
        businesses = fetchedBusinesses.where((business) {
          if (business['latitude'] == null || business['longitude'] == null) return false;

          final distance = utils.LaundryDistanceUtils.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            business['latitude'],
            business['longitude'],
          );

          return distance <= _currentRadiusKm;
        }).toList();

        if (businesses.isEmpty) {
          _currentRadiusKm += 1.0; // Increment radius if no shops found
        }
        // _displayedRadiusKm = _currentRadiusKm; // Update displayed radius - Removed as _currentRadiusKm is now the displayed radius
      }

      setState(() {
        _allShops = businesses;
        if (businesses.isNotEmpty) {
          _loadingStatus = 'Loaded ${businesses.length} shops within ${_currentRadiusKm.toInt()}km';
        } else {
          _loadingStatus = 'No shops found within ${maxRadiusKm.toInt()}km.';
        }
        _isLoading = false; // Set _isLoading to false here
      });

      await _fetchNearbyLaundryShops();

    } catch (e) {
      debugPrint('Basic loading failed: $e');
      setState(() {
        _allShops = [];
        _loadingStatus = 'No shops found.';
      });
    }
  }

  Future<void> _loadFreshDataInBackground() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id,
            business_name,
            latitude,
            longitude,
            business_address,
            business_phone_number,
            services_offered,
            service_prices,
            operating_hours,
            rating,
            total_reviews,
            exact_location,
            description
          ''');

      final freshShops = List<Map<String, dynamic>>.from(response);
      
      // Filter by 1km distance
      final filteredShops = freshShops.where((shop) {
        if (shop['latitude'] == null || shop['longitude'] == null) return false;
        
        final distance = utils.LaundryDistanceUtils.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shop['latitude'],
          shop['longitude'],
        );

        return distance <= 1.0; // 1km radius
      }).toList();
      
      if (mounted) {
        setState(() {
          _allShops = filteredShops;
          _loadingStatus = 'Found ${filteredShops.length} registered shops in 1km radius';
        });
        
        _fetchNearbyLaundryShops();
      }
    } catch (e) {
      debugPrint('Background fresh data loading failed: $e');
    }
  }

  Future<void> _fetchNearbyLaundryShops() async {
    if (_currentPosition == null) {
      debugPrint('Cannot load markers: _currentPosition is null');
      return;
    }

    // Clear existing markers except current location
    List<Marker> newMarkers = [];
    
    // Add user location marker ("you") with blue color
    newMarkers.add(
      Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Center(
            child: Icon(
              Icons.my_location,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );

    setState(() {
      _isLoadingProgressively = true;
      _markers = newMarkers;
    });

    // Network-aware batching
    final batchSize = _networkSpeed == NetworkSpeed.slow ? 3 :
                     _networkSpeed == NetworkSpeed.medium ? 5 : 8;
    final delayMs = _networkSpeed == NetworkSpeed.slow ? 1000 :
                   _networkSpeed == NetworkSpeed.medium ? 500 : 200;
    
    // int registeredLimit = _networkSpeed == NetworkSpeed.slow ? 10 :
    //                      _networkSpeed == NetworkSpeed.medium ? 20 : 30;
    // final int unregisteredLimit = 5;

    List<Map<String, dynamic>> limitedAllShops = _allShops;

    // Add registered shops in batches (green markers)
    for (int i = 0; i < limitedAllShops.length; i += batchSize) {
      if (!mounted) return;
      
      final batch = limitedAllShops.skip(i).take(batchSize);
      final batchMarkers = batch.map((shop) => 
        Marker(
          point: LatLng(
            (shop['latitude'] as double? ?? 0.0),
            (shop['longitude'] as double? ?? 0.0),
          ),
          child: GestureDetector(
            onTap: () => _showShopDetails(shop),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_laundry_service,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        )
      ).toList();
      
      setState(() {
        _markers.addAll(batchMarkers);
        // _loadingStatus = 'Loading nearby shops... ${i + batch.length}/${limitedAllShops.length}'; // Removed this line
      });
      
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (mounted) {
      setState(() {
        _isLoadingProgressively = false;

      });
    }
  }

  void _showShopDetails(Map<String, dynamic> shop) {
    final shopName = shop['business_name'] ?? 'Laundry Shop';
    final shopAddress = shop['business_address'] ?? 'No address provided';

    final distance = utils.LaundryDistanceUtils.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      shop['latitude'],
      shop['longitude'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green, // All shops are now considered 'registered'
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ LAUNDRY SHOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Distance
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${distance.toStringAsFixed(1)} km from you',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Address
                if (shopAddress.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.home, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shopAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Phone for all shops
                if (shop['business_phone_number'] != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        shop['business_phone_number'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Rating
                if (shop['rating'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        '${shop['rating'].toStringAsFixed(1)} (${shop['total_reviews'] ?? 0} reviews)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Services Offered
                if (shop['services_offered'] != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.cleaning_services, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (shop['services_offered'] as List).join(', '),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Phone Number
                if (shop['business_phone_number'] != null)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        shop['business_phone_number'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                
                // Contact button
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle contact action (e.g., call, open website)
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Contact Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Consistent color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingStatus,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C63FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Finding nearby laundry shops...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Network status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getNetworkIcon(),
                    color: _getNetworkColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getNetworkSpeedText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getNetworkColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String title, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingWidget()
          : _hasError
              ? _buildErrorWidget(
                  'Unable to Load Location',
                  _errorMessage,
                  _retryLoading,
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
                                                    color: Color(0xFF7B61FF),
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
                                          radius: _currentRadiusKm * 1000, // Convert km to meters
                                          useRadiusInMeter: true,
                                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                          borderColor: const Color(0xFF7B61FF),
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
                                      const Text('Laundry Shop', style: TextStyle(fontSize: 10, color: Colors.black)),
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
                                      Text('${_currentRadiusKm.toInt()}km Range', style: TextStyle(fontSize: 10, color: Colors.black)),
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
                                debugPrint('DEBUG: Locate button pressed');
                                debugPrint('DEBUG: _currentPosition = $_currentPosition');
                                debugPrint('DEBUG: _mapController = $_mapController');
                                
                                if (_currentPosition != null && _mapController != null) {
                                  debugPrint('DEBUG: Moving map and fetching shops');
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
                                  debugPrint('DEBUG: Cannot locate - missing position or map controller');
                                  // Try to get location if not available
                                  await _getCurrentLocation();
                                  
                                  // If still no location (common on web), use a test location
                                  if (_currentPosition == null) {
                                    debugPrint('DEBUG: Using fallback test location');
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
                                    await _loadNearbyLaundryShops();
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