import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationCache {
  static LocationCache? _instance;
  static LocationCache get instance => _instance ??= LocationCache._();
  
  LocationCache._();
  
  static const String _userLocationKey = 'cached_user_location';
  static const String _businessProfilesKey = 'cached_business_profiles';
  static const String _lastUpdateKey = 'cache_last_update';
  static const String _cacheVersionKey = 'cache_version';
  
  static const int cacheExpiryHours = 1; // Cache expires after 1 hour
  static const String cacheVersion = '1.0'; // Increment when data structure changes
  
  /// Cache user's current location
  Future<void> cacheUserLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_userLocationKey, jsonEncode(locationData));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_cacheVersionKey, cacheVersion);
      
      debugPrint('User location cached successfully');
    } catch (e) {
      debugPrint('Error caching user location: $e');
    }
  }
  
  /// Get cached user location if valid
  Future<Position?> getCachedUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final cachedVersion = prefs.getString(_cacheVersionKey);
      if (cachedVersion != cacheVersion) {
        await clearCache();
        return null;
      }
      
      // Check if cache is expired
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate == null) return null;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final cacheAgeHours = cacheAge / (1000 * 60 * 60);
      
      if (cacheAgeHours > cacheExpiryHours) {
        debugPrint('Location cache expired');
        return null;
      }
      
      // Get cached location
      final locationJson = prefs.getString(_userLocationKey);
      if (locationJson == null) return null;
      
      final locationData = jsonDecode(locationJson) as Map<String, dynamic>;
      
      return Position(
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(locationData['timestamp']),
        accuracy: locationData['accuracy'],
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    } catch (e) {
      debugPrint('Error getting cached user location: $e');
      return null;
    }
  }
  
  /// Cache business profiles data
  Future<void> cacheBusinessProfiles(List<Map<String, dynamic>> businesses, Position userLocation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cacheData = {
        'businesses': businesses,
        'userLocation': {
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_businessProfilesKey, jsonEncode(cacheData));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Business profiles cached: ${businesses.length} items');
    } catch (e) {
      debugPrint('Error caching business profiles: $e');
    }
  }
  
  /// Get cached business profiles if valid and within range
  Future<List<Map<String, dynamic>>?> getCachedBusinessProfiles(Position currentLocation, {double maxDistanceKm = 5.0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final cachedVersion = prefs.getString(_cacheVersionKey);
      if (cachedVersion != cacheVersion) {
        await clearCache();
        return null;
      }
      
      // Check if cache is expired
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate == null) return null;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final cacheAgeHours = cacheAge / (1000 * 60 * 60);
      
      if (cacheAgeHours > cacheExpiryHours) {
        debugPrint('Business profiles cache expired');
        return null;
      }
      
      // Get cached data
      final cacheJson = prefs.getString(_businessProfilesKey);
      if (cacheJson == null) return null;
      
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final cachedUserLocation = cacheData['userLocation'] as Map<String, dynamic>;
      
      // Check if current location is close to cached location
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        cachedUserLocation['latitude'],
        cachedUserLocation['longitude'],
      ) / 1000; // Convert to km
      
      if (distance > maxDistanceKm) {
        debugPrint('User moved too far from cached location: ${distance.toStringAsFixed(2)}km');
        return null;
      }
      
      final businesses = (cacheData['businesses'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      debugPrint('Retrieved ${businesses.length} cached business profiles');
      return businesses;
    } catch (e) {
      debugPrint('Error getting cached business profiles: $e');
      return null;
    }
  }
  
  /// Check if location cache is valid
  Future<bool> isLocationCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final cachedVersion = prefs.getString(_cacheVersionKey);
      if (cachedVersion != cacheVersion) return false;
      
      // Check if cache exists and is not expired
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate == null) return false;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      final cacheAgeHours = cacheAge / (1000 * 60 * 60);
      
      return cacheAgeHours <= cacheExpiryHours;
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userLocationKey);
      await prefs.remove(_businessProfilesKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_cacheVersionKey);
      
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      final hasLocationCache = prefs.containsKey(_userLocationKey);
      final hasBusinessCache = prefs.containsKey(_businessProfilesKey);
      
      String cacheAge = 'Unknown';
      if (lastUpdate != null) {
        final ageMs = DateTime.now().millisecondsSinceEpoch - lastUpdate;
        final ageMinutes = ageMs / (1000 * 60);
        if (ageMinutes < 60) {
          cacheAge = '${ageMinutes.toInt()} minutes';
        } else {
          final ageHours = ageMinutes / 60;
          cacheAge = '${ageHours.toStringAsFixed(1)} hours';
        }
      }
      
      return {
        'hasLocationCache': hasLocationCache,
        'hasBusinessCache': hasBusinessCache,
        'cacheAge': cacheAge,
        'isValid': await isLocationCacheValid(),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {
        'hasLocationCache': false,
        'hasBusinessCache': false,
        'cacheAge': 'Error',
        'isValid': false,
      };
    }
  }
}