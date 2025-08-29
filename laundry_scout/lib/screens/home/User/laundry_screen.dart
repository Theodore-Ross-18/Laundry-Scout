import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_detail_screen.dart'; // Add this import

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _laundryShops = [];
  List<Map<String, dynamic>> _filteredLaundryShops = [];
  bool _isLoading = true;

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
          .select('id, business_name, exact_location, cover_photo_url, does_delivery');

      if (mounted) {
        setState(() {
          _laundryShops = List<Map<String, dynamic>>.from(response);
          _filteredLaundryShops = _laundryShops;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading laundry shops: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading laundry shops: $e')),
        );
      }
    }
  }

  void _filterLaundryShops(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLaundryShops = _laundryShops;
      });
    } else {
      setState(() {
        final lowerCaseQuery = query.toLowerCase();
        _filteredLaundryShops = _laundryShops.where((shop) {
          final businessName = shop['business_name']?.toLowerCase() ?? '';
          final location = shop['exact_location']?.toLowerCase() ?? '';
          return businessName.contains(lowerCaseQuery) || location.contains(lowerCaseQuery);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFF6F5ADC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Laundry Scout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterLaundryShops,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Search Here',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.filter_list, color: Color(0xFF6F5ADC)),
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
                            'No laundry shops found.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLaundryShops,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredLaundryShops.length,
                            itemBuilder: (context, index) {
                              final shop = _filteredLaundryShops[index];
                              return _buildLaundryShopCard(shop);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaundryShopCard(Map<String, dynamic> shop) {
    return GestureDetector( // Wrap the entire card with GestureDetector
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
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                image: shop['cover_photo_url'] != null
                    ? DecorationImage(
                        image: NetworkImage(shop['cover_photo_url']),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('lib/assets/laundry_placeholder.png'),
                        fit: BoxFit.cover,
                      ),
              ),
              child: Stack(
                children: [
                  // Rating Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8', // You can make this dynamic based on actual ratings
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop['exact_location'] ?? 'Location not available',
                          style: TextStyle(
                            fontSize: 14,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delivery Badge
                      if (shop['does_delivery'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6F5ADC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              color: const Color(0xFF6F5ADC),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
}