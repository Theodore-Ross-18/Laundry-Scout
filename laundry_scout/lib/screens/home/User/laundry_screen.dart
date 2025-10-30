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
          .select('id, business_name, business_address, cover_photo_url, does_delivery, services_offered')
          .eq('status', 'approved');

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
    
   
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      filtered = filtered.where((shop) {
        final businessName = shop['business_name']?.toString().toLowerCase() ?? '';
        final location = shop['exact_location']?.toString().toLowerCase() ?? '';
        return businessName.contains(lowerCaseQuery) || location.contains(lowerCaseQuery);
      }).toList();
    }
    
   
    if (_currentFilters['selectedServices'] != null &&
        (_currentFilters['selectedServices'] as List).isNotEmpty) {
      filtered = filtered.where((shop) {
        List<String> selectedServices = List<String>.from(_currentFilters['selectedServices']);
        List<String> shopServices = List<String>.from(shop['services_offered'] ?? []);

        bool hasService = false;
        for (String service in selectedServices) {
          if (shopServices.contains(service)) {
            hasService = true;
            break;
          }
        }
        return hasService;
      }).toList();
    }
    
    
    if (_currentFilters['minimumRating'] != null && 
        _currentFilters['minimumRating'] > 0) {
      
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
          
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF5A35E3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
               
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.asset('lib/assets/icons/filter.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
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
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  Text(
                    shop['business_name'] ?? 'Laundry Shop',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                 
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
                 
                  Row(
                    children: [
                      if (shop['services_offered'] != null)
                        ...(shop['services_offered'] as List<dynamic>).map((service) {
                          Color backgroundColor;
                          Color textColor;
                          switch (service) {
                            case 'Iron Only':
                              backgroundColor = Colors.orange.withOpacity(0.1);
                              textColor = Colors.orange[700]!;
                              break;
                            case 'Wash & Fold':
                              backgroundColor = const Color(0xFF5A35E3).withOpacity(0.1);
                              textColor = const Color(0xFF5A35E3);
                              break;
                            case 'Clean & Iron':
                              backgroundColor = Colors.green.withOpacity(0.1);
                              textColor = Colors.green[700]!;
                              break;
                            default:
                              backgroundColor = Colors.grey.withOpacity(0.1);
                              textColor = Colors.grey[700]!;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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