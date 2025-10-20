import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../widgets/optimized_image.dart';

class OwnerPromoPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> promoData;

  const OwnerPromoPreviewScreen({
    super.key,
    required this.promoData,
  });

  @override
  State<OwnerPromoPreviewScreen> createState() => _OwnerPromoPreviewScreenState();
}

class _OwnerPromoPreviewScreenState extends State<OwnerPromoPreviewScreen> {
  Map<String, dynamic>? _businessData;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

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
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _businessData = response;
        });
      }
    } catch (e) {
      debugPrint('Error loading business data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business data: $e')),
        );
      }
    }
  }

  Widget _buildPreviewImage(String imageUrl) {
    // Check if it's a local file path (for preview)
    if (!imageUrl.startsWith('http') && !kIsWeb) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    
    return OptimizedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoImageUrl = widget.promoData['image_url'] as String?;
    final promoTitle = widget.promoData['promo_title'] as String? ?? 'Special Promo';
    final promoDescription = widget.promoData['promo_description'] as String? ?? 'Check out this amazing offer!';
    final businessName = _businessData?['business_name'] ?? 'Your Laundry Shop';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: promoImageUrl != null
                  ? _buildPreviewImage(promoImageUrl)
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
                color: Colors.black.withValues(alpha: 0.5),
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
                  // Business Name
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
                      color: const Color(0xFF5A35E3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF5A35E3).withValues(alpha: 0.2),
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
                  
                  // Preview Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A35E3).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5A35E3).withValues(alpha: 0.2),  
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF5A35E3),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Preview Mode',
                              style: TextStyle(
                                color: const Color(0xFF5A35E3),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is how your promo will appear to customers. Make sure the image, title, and description look good before publishing.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
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