import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class PlacesService {
  // Using OpenStreetMap Overpass API (FREE alternative to Google Places)
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  // Search for laundry shops within specified radius using OpenStreetMap
  static Future<List<Map<String, dynamic>>> searchLaundryShops({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000, // 5km default
  }) async {
    try {
      // DEBUG PlacesService: Searching with radius $radiusMeters meters
      
      // Create Overpass QL query for laundry-related amenities
      final query = '''
[out:json][timeout:25];
(
  node["shop"="laundry"](around:$radiusMeters,$latitude,$longitude);
  node["shop"="dry_cleaning"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="laundry"](around:$radiusMeters,$latitude,$longitude);
  way["shop"="laundry"](around:$radiusMeters,$latitude,$longitude);
  way["shop"="dry_cleaning"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="laundry"](around:$radiusMeters,$latitude,$longitude);
  relation["shop"="laundry"](around:$radiusMeters,$latitude,$longitude);
  relation["shop"="dry_cleaning"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="laundry"](around:$radiusMeters,$latitude,$longitude);
);
out center meta;
''';
      
      // DEBUG PlacesService: Query prepared
      
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'LaundryScout/1.0 (Flutter App)',
        },
        body: 'data=${Uri.encodeComponent(query)}',
      );
      
      // DEBUG PlacesService: Response received
      // DEBUG PlacesService: Response body processed
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['elements'] != null) {
          List<Map<String, dynamic>> shops = [];
          
          for (var element in data['elements']) {
            final shop = _formatOSMData(element);
            if (shop != null) {
              shops.add(shop);
            }
          }
          
          return shops;
        }
      } else {
        developer.log('Overpass API error: ${response.statusCode}', name: 'PlacesService');
        return [];
      }
      
      return [];
    } catch (e) {
      developer.log('Error searching laundry shops: $e', name: 'PlacesService');
      return [];
    }
  }
  
  // Format OpenStreetMap data for our database
  static Map<String, dynamic>? _formatOSMData(Map<String, dynamic> element) {
    try {
      double? lat, lon;
      
      // Handle different element types (node, way, relation)
      if (element['type'] == 'node') {
        lat = element['lat']?.toDouble();
        lon = element['lon']?.toDouble();
      } else if (element['center'] != null) {
        lat = element['center']['lat']?.toDouble();
        lon = element['center']['lon']?.toDouble();
      }
      
      if (lat == null || lon == null) return null;
      
      final tags = element['tags'] ?? {};
      final name = tags['name'] ?? 
                   tags['brand'] ?? 
                   _generateNameFromTags(tags) ?? 
                   'Laundry Service';
      
      return {
        'business_name': name,
        'latitude': lat,
        'longitude': lon,
        'exact_location': _buildAddress(tags),
        'phone': tags['phone'],
        'description': _buildDescription(tags),
      };
    } catch (e) {
      developer.log('Error formatting OSM data: $e', name: 'PlacesService');
      return null;
    }
  }
  
  // Generate name from OSM tags if no name is provided
  static String _generateNameFromTags(Map<String, dynamic> tags) {
    if (tags['brand'] != null) return tags['brand'];
    if (tags['operator'] != null) return tags['operator'];
    
    final shop = tags['shop'];
    final amenity = tags['amenity'];
    
    if (shop == 'laundry') return 'Laundry Shop';
    if (shop == 'dry_cleaning') return 'Dry Cleaning';
    if (amenity == 'laundry') return 'Laundromat';
    
    return 'Laundry Service';
  }
  
  // Build address from OSM tags
  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];
    
    if (tags['addr:housenumber'] != null) {
      addressParts.add(tags['addr:housenumber']);
    }
    if (tags['addr:street'] != null) {
      addressParts.add(tags['addr:street']);
    }
    if (tags['addr:city'] != null) {
      addressParts.add(tags['addr:city']);
    }
    if (tags['addr:postcode'] != null) {
      addressParts.add(tags['addr:postcode']);
    }
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Address not available';
  }

  // Build description from OSM tags
  static String _buildDescription(Map<String, dynamic> tags) {
    List<String> descriptionParts = [];
    
    // Add service type
    if (tags['shop'] == 'laundry') {
      descriptionParts.add('Laundry shop');
    } else if (tags['shop'] == 'dry_cleaning') {
      descriptionParts.add('Dry cleaning service');
    } else if (tags['amenity'] == 'laundry') {
      descriptionParts.add('Laundromat');
    } else {
      descriptionParts.add('Laundry service');
    }
    
    // Add brand/operator if available
    if (tags['brand'] != null) {
      descriptionParts.add('Brand: ${tags['brand']}');
    } else if (tags['operator'] != null) {
      descriptionParts.add('Operated by: ${tags['operator']}');
    }
    
    // Add website if available
    if (tags['website'] != null) {
      descriptionParts.add('Website: ${tags['website']}');
    }
    
    // Add opening hours if available
    if (tags['opening_hours'] != null) {
      descriptionParts.add('Hours: ${tags['opening_hours']}');
    }
    
    return descriptionParts.join(' • ');
  }
  

  // Get additional details using Nominatim (reverse geocoding)
  static Future<Map<String, dynamic>?> getPlaceDetails(String osmId) async {
    try {
      // Extract OSM type and ID from our custom place_id format
      final parts = osmId.split('_');
      if (parts.length < 3) return null;
      
      final osmType = parts[1]; // node, way, or relation
      final osmIdNumber = parts[2];
      
      final url = Uri.parse(
        '$_nominatimUrl/lookup?'
        'osm_ids=${osmType[0].toUpperCase()}$osmIdNumber&'
        'format=json&'
        'addressdetails=1&'
        'extratags=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LaundryScout/1.0 (Flutter App)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0];
        }
      }
    } catch (e) {
      developer.log('Error getting place details: $e', name: 'PlacesService');
    }
    
    return null;
  }
  
  // Search for places by text query (alternative method)
  static Future<List<Map<String, dynamic>>> searchByText({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/search?'
        'q=$query&'
        'format=json&'
        'limit=20&'
        'bounded=1&'
        'viewbox=${longitude - radiusKm/111},${latitude + radiusKm/111},${longitude + radiusKm/111},${latitude - radiusKm/111}&'
        'addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LaundryScout/1.0 (Flutter App)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> results = [];
        
        for (var place in data) {
          if (_isLaundryRelated(place['display_name'] ?? '')) {
            final formatted = _formatNominatimData(place);
            if (formatted != null) {
              results.add(formatted);
            }
          }
        }
        
        return results;
      }
    } catch (e) {
      developer.log('Error searching by text: $e', name: 'PlacesService');
    }
    
    return [];
  }
  
  // Format Nominatim search results
  static Map<String, dynamic>? _formatNominatimData(Map<String, dynamic> place) {
    try {
      final displayName = place['display_name'] ?? '';
      final nameParts = displayName.split(',');
      final businessName = nameParts.isNotEmpty ? nameParts[0].trim() : 'Laundry Service';
      
      return {
        'business_name': businessName,
        'latitude': double.parse(place['lat']),
        'longitude': double.parse(place['lon']),
        'exact_location': displayName,
        'phone': null, // Nominatim doesn't provide phone numbers
        'description': 'Laundry service found via text search • Type: ${place['type'] ?? 'laundry'}',
      };
    } catch (e) {
      developer.log('Error formatting Nominatim data: $e', name: 'PlacesService');
      return null;
    }
  }
  
  // Check if place name suggests it's laundry-related
  static bool _isLaundryRelated(String name) {
    final lowerName = name.toLowerCase();
    final keywords = [
      'laundry', 'laundromat', 'wash', 'dry clean', 'cleaning',
      'coin', 'self service', 'wash and fold', 'dry cleaning'
    ];
    
    return keywords.any((keyword) => lowerName.contains(keyword));
  }
}