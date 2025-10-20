import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_detail_screen.dart';
import '../../../widgets/optimized_image.dart';

class PromoPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> promoData;

  const PromoPreviewScreen({
    super.key,
    required this.promoData,
  });

  @override
  State<PromoPreviewScreen> createState() => _PromoPreviewScreenState();
}

class _PromoPreviewScreenState extends State<PromoPreviewScreen> {
  Map<String, dynamic>? _businessData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id, 
            business_name, 
            exact_location, 
            cover_photo_url, 
            does_delivery, 
            availability_status,
            business_phone_number,
            services_offered,
            service_prices,
            open_hours,
            available_pickup_time_slots,
            available_dropoff_time_slots,
            latitude,
            longitude
          ''')
          .eq('id', widget.promoData['business_id'])
          .single();

      if (mounted) {
        setState(() {
          _businessData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading business data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business data: $e')),
        );
      }
    }
  }

  void _navigateToBusinessDetail() {
    if (_businessData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessDetailScreen(
            businessData: _businessData!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promoImageUrl = widget.promoData['image_url'] as String?;
    final promoTitle = widget.promoData['promo_title'] as String? ?? 'Special Promo';
    final promoDescription = widget.promoData['promo_description'] as String? ?? 'Check out this amazing offer!';
    final businessName = widget.promoData['business_profiles']?['business_name'] ?? 'Laundry Shop';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: promoImageUrl != null
                  ? OptimizedImage(
                      imageUrl: promoImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.local_offer,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    promoTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      promoDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A35E3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF5A35E3).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: const Color(0xFF5A35E3),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Valid until further notice',
                          style: TextStyle(
                            color: const Color(0xFF5A35E3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _navigateToBusinessDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A35E3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'View Laundry Shop',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}