import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/optimized_image.dart';
import 'business_detail_screen.dart';

class AllServicesRelatedScreen extends StatefulWidget {
  final String serviceName;

  const AllServicesRelatedScreen({
    super.key,
    required this.serviceName,
  });

  @override
  State<AllServicesRelatedScreen> createState() => _AllServicesRelatedScreenState();
}

class _AllServicesRelatedScreenState extends State<AllServicesRelatedScreen> {
  List<Map<String, dynamic>> _laundryShops = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLaundryShopsWithService();
  }

  Future<void> _loadLaundryShopsWithService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id, 
            business_name, 
            business_address, 
            cover_photo_url, 
            does_delivery, 
            availability_status,
            services_offered,
            feedback(rating)
          ''')
          .eq('status', 'approved')
          .eq('feedback.feedback_type', 'user');

      // Filter shops that offer the specific service
      final filteredShops = response.where((shop) {
        final servicesOffered = shop['services_offered'];
        if (servicesOffered == null) return false;
        
        if (servicesOffered is List) {
          return servicesOffered.any((service) => 
            service.toString().toLowerCase().contains(widget.serviceName.toLowerCase())
          );
        } else if (servicesOffered is String) {
          return servicesOffered.toLowerCase().contains(widget.serviceName.toLowerCase());
        }
        return false;
      }).toList();

      // Process shops with ratings
      final processedShops = filteredShops.map((shop) {
        final feedbackList = shop['feedback'] as List<dynamic>? ?? [];
        double averageRating = 0.0;
        int totalReviews = 0;
        
        if (feedbackList.isNotEmpty) {
          double totalRating = 0.0;
          for (var feedback in feedbackList) {
            if (feedback['rating'] != null) {
              totalRating += (feedback['rating'] as num).toDouble();
              totalReviews++;
            }
          }
          if (totalReviews > 0) {
            averageRating = totalRating / totalReviews;
          }
        }
        
        return {
          ...shop,
          'average_rating': averageRating,
          'total_reviews': totalReviews,
          'feedback': null,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _laundryShops = List<Map<String, dynamic>>.from(processedShops);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading laundry shops with service: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading laundry shops: $e';
        });
      }
    }
  }

  Widget _buildAvailabilityStatusBadge(String? availabilityStatus) {
    String status = availabilityStatus ?? 'Unavailable';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Open Slots':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Filling Up':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'Full':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Unavailable':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        status = 'Unavailable';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBusinessDetail(Map<String, dynamic> business) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailScreen(
          businessData: business,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.serviceName} Services'),
        backgroundColor: const Color(0xFF5A35E3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLaundryShopsWithService,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _laundryShops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No laundry shops found offering ${widget.serviceName}',
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _laundryShops.length,
                      itemBuilder: (context, index) {
                        final shop = _laundryShops[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          color: const Color(0xFF5A35E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToBusinessDetail(shop),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Shop Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: shop['cover_photo_url'] != null
                                          ? OptimizedImage(
                                              imageUrl: shop['cover_photo_url'],
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.business,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Shop Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                shop['business_name'] ?? 'Unknown Shop',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _buildAvailabilityStatusBadge(shop['availability_status']),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          shop['business_address'] ?? 'No address available',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // Rating
                                            if (shop['average_rating'] > 0) ...[
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${shop['average_rating'].toStringAsFixed(1)}',
                                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${shop['total_reviews']} reviews)',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ] else ...[
                                              const Text(
                                                'No reviews yet',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            // Delivery indicator
                                            if (shop['does_delivery'] == true)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.delivery_dining,
                                                      size: 14,
                                                      color: Colors.green,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Delivery',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}