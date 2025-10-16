import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_detail_screen.dart';
import '../../../widgets/optimized_image.dart';
import '../../../widgets/filter_modal.dart';
import '../../../services/feedback_service.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _laundryShops = [];
  List<Map<String, dynamic>> _filteredLaundryShops = [];
  Map<String, dynamic> _currentFilters = {};
  bool _isLoading = true;
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _loadLaundryShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLaundryShops() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name, business_address, cover_photo_url, does_delivery')
          .eq('status', 'approved'); // Only fetch approved businesses

      if (mounted) {
        setState(() {
          _laundryShops = List<Map<String, dynamic>>.from(response);
          _filteredLaundryShops = _laundryShops;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error loading laundry shops: $e
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterLaundryShops(String query) {
    setState(() {
      _applyFilters(searchQuery: query);
    });
  }

  void _applyFilters({String? searchQuery}) {
    List<Map<String, dynamic>> filtered = List.from(_laundryShops);
    
    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      filtered = filtered.where((shop) {
        final businessName = shop['business_name']?.toString().toLowerCase() ?? '';
        final location = shop['exact_location']?.toString().toLowerCase() ?? '';
        return businessName.contains(lowerCaseQuery) || location.contains(lowerCaseQuery);
      }).toList();
    }
    
    // Apply service filters
    if (_currentFilters['selectedServices'] != null && 
        (_currentFilters['selectedServices'] as List).isNotEmpty) {
      filtered = filtered.where((shop) {
        List<String> selectedServices = List<String>.from(_currentFilters['selectedServices']);
        
        // Check if shop offers any of the selected services
        bool hasService = false;
        
        for (String service in selectedServices) {
          switch (service) {
            case 'Delivery':
              if (shop['does_delivery'] == true) hasService = true;
              break;
            case 'Drop Off':
            case 'Pick Up':
            case 'Wash & Fold':
            case 'Self Service':
            case 'Dry Clean':
            case 'Ironing':
              // For now, assume all shops offer these basic services
              hasService = true;
              break;
          }
          if (hasService) break;
        }
        
        return hasService;
      }).toList();
    }
    
    // Apply rating filter (placeholder - you can implement actual rating logic)
    if (_currentFilters['minimumRating'] != null && 
        _currentFilters['minimumRating'] > 0) {
      // For now, we'll keep all shops since we don't have rating data
      // In a real app, you would filter based on actual ratings
    }
    
    _filteredLaundryShops = filtered;
  }

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FilterModal(
          currentFilters: _currentFilters,
          onApplyFilters: (Map<String, dynamic> filters) {
            setState(() {
              _currentFilters = filters;
              _applyFilters(searchQuery: _searchController.text);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Header with title
                Image.asset(
                  'lib/assets/lslogo.png',
                  height: 40, // Adjust height as needed
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                const SizedBox(height: 10), // Spacing between logo and text
                const Text(
                  'Laundry Scout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterLaundryShops,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search Here',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterModal,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune, color: Color(0xFF7B61FF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLaundryShops.isEmpty
                    ? const Center(
                        child: Text(
                          'No laundry shops found',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredLaundryShops.length,
                        itemBuilder: (context, index) {
                          final shop = _filteredLaundryShops[index];
                          return _buildLaundryShopCard(shop);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaundryShopCard(Map<String, dynamic> shop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessDetailScreen(businessData: shop),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Rating Badge
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: shop['cover_photo_url'] != null
                        ? OptimizedImage(
                            imageUrl: shop['cover_photo_url'],
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorWidget: Image.asset(
                              'lib/assets/laundry_placeholder.png',
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'lib/assets/laundry_placeholder.png',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                // Rating Badge with FutureBuilder
                Positioned(
                  top: 12,
                  left: 12,
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _getBusinessRating(shop['id']),
                    builder: (context, snapshot) {
                      double rating = 0.0;
                      if (snapshot.hasData) {
                        rating = snapshot.data!['averageRating'] ?? 0.0;
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name
                  Text(
                    shop['business_name'] ?? 'Laundry Shop',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                                    shop['business_address'] ?? 'Location not available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Service Badges
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Open Slots',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Service Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          shop['does_delivery'] == true ? 'Wash & Fold' : 'Drop Off',
                          style: const TextStyle(
                            color: Color(0xFF7B61FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (shop['does_delivery'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getBusinessRating(String businessId) async {
    try {
      final feedback = await _feedbackService.getFeedback(businessId);
      return _feedbackService.getFeedbackStats(feedback);
    } catch (e) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
      };
    }
  }
}