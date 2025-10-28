import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/optimized_image.dart';
import 'promo_preview.dart';

class AllPromosScreen extends StatefulWidget {
  const AllPromosScreen({super.key});

  @override
  State<AllPromosScreen> createState() => _AllPromosScreenState();
}

class _AllPromosScreenState extends State<AllPromosScreen> {
  List<Map<String, dynamic>> _allPromos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPromos();
  }

  Future<void> _loadAllPromos() async {
    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*, business_profiles(business_name)');

      if (mounted) {
        setState(() {
          _allPromos = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading all promos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading all promos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Promos'),
        backgroundColor: const Color(0xFF5A35E3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allPromos.isEmpty
              ? const Center(child: Text('No promos available.'))
              : ListView.builder(
                  itemCount: _allPromos.length,
                  itemBuilder: (context, index) {
                    final promo = _allPromos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PromoPreviewScreen(promoData: promo),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              promo['image_url'] != null
                                  ? OptimizedImage(
                                      imageUrl: promo['image_url'],
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorWidget: Image.asset(
                                        'lib/assets/promo_example.png',
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      'lib/assets/promo_example.png',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
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