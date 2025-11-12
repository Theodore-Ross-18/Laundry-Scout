import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart';
import '../../../widgets/optimized_image.dart';
import 'order_placement_screen.dart';
import '../../../services/feedback_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:laundry_scout/screens/home/User/getdirection.dart';
import 'package:flutter/services.dart';
import 'image_preview_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessDetailScreen({
    super.key,
    required this.businessData,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _fullBusinessData;
  bool _isLoading = true;
  late TabController _tabController;
  List<String> _galleryImageUrls = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _pricelist = [];
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 
    _loadFullBusinessData().then((_) {

      _loadPricelist();
      _loadReviews();
      _debugBusinessData();
    });
  }

  Future<void> _debugBusinessData() async {
    try {
      
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name, services_offered, service_prices')
          .eq('id', widget.businessData['id'])
          .single();
      
      print('=== DEBUG CURRENT BUSINESS DATA ===');
      print('Business ID: ${response['id']}');
      print('Business Name: ${response['business_name']}');
      print('Services Offered: ${response['services_offered']}');
      print('Services Offered Type: ${response['services_offered'].runtimeType}');
      print('Service Prices: ${response['service_prices']}');
      print('Service Prices Type: ${response['service_prices'].runtimeType}');
      
      if (response['service_prices'] is List) {
        print('Service Prices as List:');
        for (var item in response['service_prices']) {
          print('  Item: $item');
          print('  Item Type: ${item.runtimeType}');
          if (item is Map) {
            print('  Service: ${item['service']}');
            print('  Price: ${item['price']}');
          }
        }
      } else if (response['service_prices'] is Map) {
        print('Service Prices as Map:');
        response['service_prices'].forEach((key, value) {
          print('  $key: $value');
        });
      }
      
    
      print('=== LOADED PRICELIST ===');
      print('Pricelist length: ${_pricelist.length}');
      for (var item in _pricelist) {
        print('  Service: ${item['service_name']}, Price: ${item['price']}');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error debugging business data: $e');
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
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackService.unsubscribeFromFeedback(widget.businessData['id']);
    super.dispose();
  }

  Widget _buildCoverImage() {
    
    final coverPhotoUrl = _fullBusinessData!['cover_photo_url'] as String?;
    
    if (coverPhotoUrl != null) {
     
      return OptimizedImage(
        imageUrl: coverPhotoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
     
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.business,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  Future<void> _loadFullBusinessData() async {
    try {
        final response = await Supabase.instance.client
            .from('business_profiles')
            .select('*, availability_status, business_phone_number, services_offered, service_prices, open_hours, available_pickup_time_slots, available_dropoff_time_slots, does_delivery, latitude, longitude, business_address, gallery_image_urls, cover_photo_url') // Add new columns here
            .eq('id', widget.businessData['id'])
            .single();
      
      setState(() {
        _fullBusinessData = response;
        _galleryImageUrls = List<String>.from(response['gallery_image_urls'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fullBusinessData = widget.businessData;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final feedback = await _feedbackService.getFeedback(widget.businessData['id']);
      setState(() {
        _reviews = feedback;
      });
      
     
      _feedbackService.subscribeToFeedback(widget.businessData['id'], (feedback) {
        if (mounted) {
          setState(() {
            _reviews = feedback;
          });
        }
      });
    } catch (e) {
      // Error handled by service
    }
  }

  Future<void> _loadPricelist() async {
    try {
      
      final servicePricesData = _fullBusinessData?['service_prices'];
      print('DEBUG: service_prices from business profile = $servicePricesData');
      
      if (servicePricesData != null && servicePricesData is List && servicePricesData.isNotEmpty) {
        
        List<Map<String, dynamic>> pricelist = [];
        
        for (var item in servicePricesData) {
          if (item is Map<String, dynamic>) {
            String serviceName = item['service'] ?? item['service_name'] ?? '';
            String priceStr = '';
            double price = 0.0;
            
            if (item['price'] != null) {
              price = double.tryParse(item['price'].toString()) ?? 0.0;
              priceStr = price.toStringAsFixed(2);
            } else {
              priceStr = '0.00';
            }
            
            
            if (serviceName.isNotEmpty && price > 0.0) {
              pricelist.add({
                'service_name': serviceName,
                'price': priceStr,
                'description': _getServiceDescription(serviceName),
              });
            }
          }
        }
        
        print('DEBUG: Formatted pricelist from service_prices = $pricelist');
        
        setState(() {
          _pricelist = pricelist;
        });
        print('DEBUG: Business detail _pricelist set from service_prices: $_pricelist');
        return;
      }
      
      final pricelistResponse = await Supabase.instance.client
          .from('pricelist')
          .select('*')
          .eq('business_id', widget.businessData['id'])
          .order('service_name');
      
      print('DEBUG: Pricelist from database = $pricelistResponse');
      
      if (pricelistResponse.isNotEmpty) {
        
        List<Map<String, dynamic>> pricelist = pricelistResponse.map((item) {
          String priceStr = '';
          if (item['price'] != null) {
            double price = double.tryParse(item['price'].toString()) ?? 0.0;
            priceStr = price.toStringAsFixed(2);
          } else {
            priceStr = '0.00';
          }
          
          return {
            'service_name': item['service_name'] ?? item['service'] ?? '',
            'price': priceStr,
            'description': _getServiceDescription(item['service_name'] ?? item['service'] ?? ''),
          };
        }).toList();
        
        print('DEBUG: Formatted pricelist = $pricelist');
      
      setState(() {
        _pricelist = pricelist;
      });
      print('DEBUG: Business detail _pricelist set to: $_pricelist');
      return;
      }
      
      final servicesOfferedData = _fullBusinessData?['services_offered'];
      print('DEBUG: No service_prices found, using services_offered = $servicesOfferedData');
      
      if (servicesOfferedData is List) {
        List<Map<String, dynamic>> pricelist = [];
        print('DEBUG: services_offered is List, processing ${servicesOfferedData.length} items');
        
        for (var serviceName in servicesOfferedData) {
          print('DEBUG: Processing service: $serviceName (type: ${serviceName.runtimeType})');
          if (serviceName is String) {
           
            String defaultPrice = _getDefaultPrice(serviceName);
            String description = _getServiceDescription(serviceName);
            
            print('DEBUG: Created service - name: $serviceName, price: $defaultPrice, desc: $description');
            
            pricelist.add({
              'service_name': serviceName,
              'price': defaultPrice,
              'description': description,
            });
          } else {
            print('DEBUG: Service is not a String, skipping');
          }
        }
        
        print('DEBUG: Created default pricelist = $pricelist');
        
        setState(() {
          _pricelist = pricelist;
        });
        print('DEBUG: Business detail _pricelist set to default: $_pricelist');
      } else {
        print('DEBUG: services_offered is not a List or is null');
      }
    } catch (e) {
      print('DEBUG: Error in _loadPricelist: $e');
      setState(() {
        _pricelist = [];
      });
    }
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'Wash & Fold':
        return 'Complete washing and folding service';
      case 'Ironing':
        return 'Professional ironing service';
      case 'Deliver':
        return 'Pickup and delivery service';
      case 'Dry Cleaning':
        return 'Professional dry cleaning';
      case 'Pressing':
        return 'Professional pressing service';
      default:
        return 'Professional laundry service';
    }
  }

  String _getDefaultPrice(String service) {
    
    switch (service.toLowerCase()) {
      case 'wash & fold':
        return '50.00';
      case 'ironing':
        return '30.00';
      case 'deliver':
      case 'delivery':
        return '20.00';
      case 'dry cleaning':
      case 'dry clean':
        return '80.00';
      case 'pressing':
        return '25.00';
      case 'pick up':
        return '15.00';
      case 'drop off':
        return '10.00';
      case 'self service':
        return '40.00';
      default:
        return '45.00';
    }
  }

// Icons at Services Available
  IconData _getServiceIcon(String? serviceName) {
    switch ((serviceName ?? '').toLowerCase()) {
      case 'pick-up':
      case 'pick up':
        return Icons.volunteer_activism; // hand/heart
      case 'drop-off':
      case 'drop off':
        return Icons.inbox;
      case 'wash & fold':
      case 'wash and fold':
        return Icons.inventory_2;
      case 'delivery':
      case 'deliver':
        return Icons.delivery_dining;
      case 'dry clean':
      case 'dry cleaning':
        return Icons.dry_cleaning;
      case 'iron only':
      case 'ironing':
        return Icons.iron;
      default:
        return Icons.local_laundry_service;
    }
  }
  double _calculateAverageRating() {
    
    final userReviews = _reviews.where((review) => 
      review['user_profiles'] != null && 
      review['user_profiles']['first_name'] != null
    ).toList();
    
    if (userReviews.isEmpty) return 0.0;
    
    final totalRating = userReviews.fold(0.0, (sum, review) => sum + (review['rating'] ?? 0));
    return totalRating / userReviews.length;
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to leave a review', style: TextStyle(color: Colors.white))),
      );
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review', style: TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:', style: TextStyle(color: Colors.black)),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about your experience...',
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _feedbackService.addReview(
                  businessId: widget.businessData['id'],
                  userId: user.id,
                  rating: selectedRating,
                  comment: commentController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted successfully', style: TextStyle(color: Colors.white))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit review: $e', style: const TextStyle(color: Colors.white))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A35E3),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (_galleryImageUrls.isEmpty) {
      return const Center(
        child: Text(
          'No gallery images available.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _galleryImageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagePreviewScreen(
                  imageUrls: _galleryImageUrls,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: OptimizedImage(
              imageUrl: _galleryImageUrls[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }


  Future<void> _placeOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPlacementScreen(
          businessData: _fullBusinessData!,
         
          availablePickupTimeSlots: List<String>.from(_fullBusinessData!['available_pickup_time_slots'] ?? []),
          availableDropoffTimeSlots: List<String>.from(_fullBusinessData!['available_dropoff_time_slots'] ?? []),
        ),
      ),
    );
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Unknown';

    try {
      final DateTime reviewDate = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(reviewDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildReviewsTab() {

    final userReviews = _reviews.where((review) =>
      review['user_profiles'] != null &&
      review['user_profiles']['first_name'] != null
    ).toList();

    double averageRating = _calculateAverageRating();
    int totalReviews = userReviews.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  totalReviews == 1 ? 'Review' : 'Reviews',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalReviews > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on $totalReviews ${totalReviews == 1 ? 'Review' : 'Reviews'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (userReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No user reviews yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            ...(userReviews.map((review) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF5A35E3),
                        child: Text(
                          (review['user_profiles']?['first_name']?[0] ?? 'U').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review['user_profiles']?['first_name'] ?? 'Anonymous'} ${review['user_profiles']?['last_name'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  review['rating']?.toString() ?? '0',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTimeAgo(review['created_at']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (review['comment'] != null && review['comment'].toString().isNotEmpty)
                    Text(
                      review['comment'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            )).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showReviewDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A35E3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Make a Review',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _fullBusinessData == null
              ? const Center(
                  child: Text(
                    'Business details not found.',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          
                          Positioned.fill(
                            child: _buildCoverImage(),
                          ),
                         
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          
                          Positioned(
                            top: 40,
                            left: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                         
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _fullBusinessData!['business_name'] ?? 'Business Name',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      _buildAvailabilityStatusBadge(_fullBusinessData!['availability_status']),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _fullBusinessData!['business_address'] ?? 'Location not available',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF5A35E3),
                        labelColor: const Color(0xFF5A35E3),
                        unselectedLabelColor: Colors.grey,
                        tabAlignment: TabAlignment.fill,
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Order'),
                          Tab(text: 'Gallery'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                    // TabBarView
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAboutTab(),
                          _buildOrderTab(),
                          _buildGalleryTab(),
                          _buildReviewsTab(),
                        ],
                      ),
                    ),
                  ], // Column children
                ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullBusinessData!['about_business'] ?? 'Welcome to our laundry service! We provide professional laundry services with care and attention to detail.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Open Hours
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullBusinessData!['open_hours'] ?? 'Open hours not available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Delivery Service
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _fullBusinessData!['does_delivery'] == true ? Icons.check_circle : Icons.cancel,
                      color: _fullBusinessData!['does_delivery'] == true ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fullBusinessData!['does_delivery'] == true ? 'Available' : 'Not Available',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Contact Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final phoneNumber = _fullBusinessData!['business_phone_number'] ??
                                          _fullBusinessData!['contact_number'] ??
                                          'No phone number available';
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Contact Number', style: TextStyle(color: Colors.black)),
                                content: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SelectableText(
                                      phoneNumber.toString(),
                                      style: const TextStyle(color: Colors.black, fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Color(0xFF5A35E3)),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: phoneNumber.toString()));
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Phone number copied to clipboard', style: TextStyle(color: Colors.white))),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close', style: TextStyle(color: Colors.black)),
                                  )
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: const Text('Call', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                businessId: widget.businessData['id'],
                                businessName: _fullBusinessData!['business_name'] ?? 'Business',
                                businessImage: _fullBusinessData!['cover_photo_url'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message, color: Colors.white),
                        label: const Text('Message', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Address with Map
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullBusinessData!['business_address'] ?? 'Address not available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _fullBusinessData!['latitude'] != null && _fullBusinessData!['longitude'] != null
                      ? FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _fullBusinessData!['latitude'],
                              _fullBusinessData!['longitude'],
                            ),
                            initialZoom: 15.0,
                            minZoom: 15.0,
                            maxZoom: 15.0,
                            interactiveFlags: InteractiveFlag.none, // Make map non-interactive
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _fullBusinessData!['latitude'],
                                    _fullBusinessData!['longitude'],
                                  ),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'Location not available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                if (_fullBusinessData!['latitude'] != null && _fullBusinessData!['longitude'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GetDirectionScreen(
                              destinationLatitude: _fullBusinessData!['latitude'],
                              destinationLongitude: _fullBusinessData!['longitude'],
                              businessName: _fullBusinessData!['business_name'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A35E3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Direction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _buildOrderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_pricelist.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pricing information will be available soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact the business directly for pricing details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final small = screenWidth < 400;
                final filtered = _pricelist
                    .where((item) => (double.tryParse(item['price']?.toString() ?? '0') ?? 0) > 0.0)
                    .toList();
                return GridView.builder(
                  itemCount: filtered.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: small ? 70 : 92,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: small ? 12 : 14,
                        vertical: small ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['service_name'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: small ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'P${item['price']}',
                                  style: TextStyle(
                                    fontSize: small ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5A35E3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: small ? 8 : 10),
                          Container(
                            width: small ? 32 : 36,
                            height: small ? 32 : 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A35E3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getServiceIcon(item['service_name']),
                              color: const Color.fromARGB(255, 255, 255, 255),
                              size: small ? 20 : 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 24),
          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: (_fullBusinessData!['does_delivery'] == true && _fullBusinessData!['availability_status'] != 'Unavailable')
                ? ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A35E3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _fullBusinessData!['availability_status'] == 'Unavailable' 
                            ? 'Currently Unavailable' 
                            : 'Delivery Not Available for Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
