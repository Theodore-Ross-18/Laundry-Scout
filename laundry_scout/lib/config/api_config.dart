class ApiConfig {
  // OpenStreetMap API Configuration (FREE alternative)
  // No API key required for OpenStreetMap services!
  
  // API Endpoints
  static const String overpassApiUrl = 'https://overpass-api.de/api/interpreter';
  static const String nominatimApiUrl = 'https://nominatim.openstreetmap.org';
  
  // Default search parameters
  static const double defaultSearchRadius = 5; // 5 meters
  static const int maxSearchResults = 20;
  static const int requestTimeoutSeconds = 30;
  
  // User Agent for API requests (required by OSM services)
  static const String userAgent = 'LaundryScout/1.0 (Flutter App)';
  
  // Rate limiting (to be respectful to free services)
  static const Duration minRequestInterval = Duration(seconds: 1);
  
  // Validation
  static bool get isConfigured {
    return true; // Always true since no API key is needed
  }
  
  // Error messages
  static const String networkErrorMessage = 
      'Network error occurred. Please check your internet connection and try again.';
  
  static const String serviceUnavailableMessage = 
      'Map service is temporarily unavailable. Please try again later.';
  
  static const String noResultsMessage = 
      'No laundry shops found in this area. Try expanding your search radius.';
  
  // Success messages
  static const String searchSuccessMessage = 
      'Successfully found laundry shops using OpenStreetMap data!';
}