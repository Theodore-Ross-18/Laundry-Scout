import 'dart:math';

class LaundryDistanceUtils {
  /// Calculate the distance between two points using the Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    // Convert degrees to radians
    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLonRad = (lon2 - lon1) * (pi / 180);
    
    // Haversine formula
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Check if a point is within the specified radius from a center point
  static bool isWithinRadius(
    double centerLat,
    double centerLon,
    double pointLat,
    double pointLon,
    double radiusMeters,
  ) {
    final double distance = calculateDistance(
      centerLat,
      centerLon,
      pointLat,
      pointLon,
    );
    
    return distance <= radiusMeters;
  }
  
  /// Filter a list of shops to only include those within the specified radius
  static List<Map<String, dynamic>> filterShopsWithinRadius(
    List<Map<String, dynamic>> shops,
    double centerLat,
    double centerLon,
    double radiusMeters,
  ) {
    return shops.where((shop) {
      final double? shopLat = shop['latitude']?.toDouble();
      final double? shopLon = shop['longitude']?.toDouble();
      
      if (shopLat == null || shopLon == null) {
        return false; // Exclude shops without valid coordinates
      }
      
      return isWithinRadius(
        centerLat,
        centerLon,
        shopLat,
        shopLon,
        radiusMeters,
      );
    }).toList();
  }
  
  /// Format distance for display
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    } else {
      final double distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }
}