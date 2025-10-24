import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/optimized_image.dart';
import '../../../widgets/message_badge.dart';
import 'business_profile_screen.dart';
import 'add_promo_screen.dart';
import 'owner_message_screen.dart';
import 'owner_notification_screen.dart';
import 'owner_feedback_screen.dart';
import 'edit_profile_screen.dart';
import 'availability_screen.dart';
import 'orders_screen.dart';
import '../../../services/feedback_service.dart';


class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  Map<String, dynamic>? _businessProfile;
  bool _isLoading = true;
  int _selectedIndex = 0;
  Map<String, int> _orderStats = {
    'total': 0,
    'pending': 0,
    'in_progress': 0,
    'completed': 0,
  };
  int _promoCount = 0;
  int _reviewCount = 0;
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    _loadOrderStats();
    _loadPromoStats();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final businessId = await _feedbackService.getBusinessIdForOwner(user.id);
      if (businessId == null) {
        print('No business ID found for user: ${user.id}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _businessProfile = null; // Set business profile to null if not found
          });
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', businessId) 
          .single();

      if (mounted) {
        setState(() {
          _businessProfile = response;
          _isLoading = false;
        });
        _loadReviewStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('business_id', user.id);

      final orders = List<Map<String, dynamic>>.from(response);
      final stats = {
        'total': orders.length,
        'pending': orders.where((o) => o['status'] == 'pending').length,
        'in_progress': orders.where((o) => o['status'] == 'in_progress').length,
        'completed': orders.where((o) => o['status'] == 'completed').length,
      };

      if (mounted) {
        setState(() {
          _orderStats = stats;
        });
      }
    } catch (e) {
      print('Error loading order stats: $e');
    }
  }

  Future<void> _loadPromoStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('promos')
          .select('id')
          .eq('business_id', user.id);

      if (mounted) {
        setState(() {
          _promoCount = response.length;
        });
        print('Promo count: $_promoCount');
      }
    } catch (e) {
      print('Error loading promo stats: $e');
    }
  }

  Future<void> _loadReviewStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _businessProfile == null) return; 

      final businessId = _businessProfile!['id'];
      if (businessId == null) {
        print('Business ID is null, cannot load review stats.');
        return;
      }

      final allFeedback = await _feedbackService.getFeedback(businessId);

      final filteredFeedback = allFeedback.where((feedback) => feedback['user_profiles'] != null).toList();

      if (mounted) {
        setState(() {
          _reviewCount = filteredFeedback.length;
        });
        print('Review count: $_reviewCount');
      }
    } catch (e) {
      print('Error loading review stats: $e');
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    
    if (index == 0 && _selectedIndex == 0) {
      _refreshDataInBackground();
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshDataInBackground() async {
    try {
      await Future.wait([
        _loadBusinessProfileBackground(),
        _loadOrderStatsBackground(),
        _loadPromoStatsBackground(),
        _loadReviewStatsBackground(),
      ]);
    } catch (e) {
      print('Background refresh error: $e');
    }
  }

  Future<void> _loadBusinessProfileBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final businessId = await _feedbackService.getBusinessIdForOwner(user.id);
      if (businessId == null) return;

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', businessId)
          .single();

      if (mounted) {
        setState(() {
          _businessProfile = response;

        });
      }
    } catch (e) {
      print('Background business profile load error: $e');
    }
  }

  Future<void> _loadOrderStatsBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('business_id', user.id);

      final orders = List<Map<String, dynamic>>.from(response);
      final stats = {
        'total': orders.length,
        'pending': orders.where((o) => o['status'] == 'pending').length,
        'in_progress': orders.where((o) => o['status'] == 'in_progress').length,
        'completed': orders.where((o) => o['status'] == 'completed').length,
      };

      if (mounted) {
        setState(() {
          _orderStats = stats;
        });
      }
    } catch (e) {
      print('Background order stats load error: $e');
    }
  }

  Future<void> _loadPromoStatsBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('promos')
          .select('id')
          .eq('business_id', user.id);

      if (mounted) {
        setState(() {
          _promoCount = response.length;
        });
      }
    } catch (e) {
      print('Background promo stats load error: $e');
    }
  }

  Future<void> _loadReviewStatsBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _businessProfile == null) return;

      final businessId = _businessProfile!['id'];
      if (businessId == null) return;

      final allFeedback = await _feedbackService.getFeedback(businessId);
      final filteredFeedback = allFeedback.where((feedback) => feedback['user_profiles'] != null).toList();

      if (mounted) {
        setState(() {
          _reviewCount = filteredFeedback.length;
        });
      }
    } catch (e) {
      print('Background review stats load error: $e');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreenContent();
      case 1:
        return const OwnerMessageScreen();
      case 2:
        return const OwnerNotificationScreen();
      default:
        return _buildHomeScreenContent();
    }
  }

  Widget _buildHomeScreenContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _businessProfile == null
            ? const Center(child: Text('No business profile found', style: TextStyle(color: Colors.black)))
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome',
                                    style: TextStyle(
                                      color: Color(0xFF5A35E3),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    _businessProfile!["business_name"] ?? 'Business Name',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const BusinessProfileScreen()),
                                );
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, color: Color(0xFF5A35E3), size: 32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cover Photo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: OptimizedImage(
                            imageUrl: _businessProfile!["cover_photo_url"],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.business,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats and View Orders
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (context) => const OrdersScreen()),
                                          );
                                        },
                                        child: _analyticsCard(Image.asset('lib/assets/owner/history.png', width: 24, height: 24, color: Color(0xFF5A35E3)), '${_orderStats['total']}', 'Order History', Color(0xFF5A35E3)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _analyticsCard(Image.asset('lib/assets/owner/promos.png', width: 24, height: 24, color: Color(0xFF5A35E3)), '$_promoCount', 'Promos', Color(0xFF5A35E3)),
                                    ),
                                    const SizedBox(width: 8), 
                                    Expanded(
                                      child: _analyticsCard(Image.asset('lib/assets/owner/reviews.png', width: 24, height: 24, color: Color(0xFF5A35E3)), '$_reviewCount', 'Reviews', Color(0xFF5A35E3)),
                                    ),
                                    const SizedBox(width: 8), 
                                    Expanded(
                                      child: _slotAnalyticsCard(_businessProfile?['availability_status'] ?? 'Open Slots'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        child: Column(
                          children: [
                         
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AddPromoScreen()),
                                      );
                                    },
                                    child: _actionCard(Image.asset('lib/assets/owner/promos.png', width: 28, height: 28, color: Colors.deepPurple), 'Promos', Colors.deepPurple),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                      );
                                    },
                                    child: _actionCard(Image.asset('lib/assets/owner/editprofile.png', width: 28, height: 28, color: Color(0xFF5A35E3)), 'Edit Profile', Color(0xFF5A35E3)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const OwnerFeedbackScreen()),
                                      );
                                    },
                                    child: _actionCard(Image.asset('lib/assets/owner/reviews.png', width: 28, height: 28, color: Colors.deepPurple), 'Reviews', Colors.deepPurple),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AvailabilityScreen()),
                                      );
                                      
                                      if (result == true) {
                                        _loadBusinessProfile();
                                      }
                                    },
                                    child: _availabilityCard(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/home.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/home.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: user != null 
                ? MessageBadge(
                    userId: user.id,
                    child: Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Colors.black),
                  )
                : Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Colors.black),
            activeIcon: user != null 
                ? MessageBadge(
                    userId: user.id,
                    child: Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
                  )
                : Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/notification.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/notification.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF5A35E3),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }

  Widget _availabilityCard() {
    return _actionCard(Image.asset('lib/assets/owner/avail.png', width: 28, height: 28, color: Color(0xFF5A35E3)), 'Set Availability', Color(0xFF5A35E3));
  }

// Helper widgets:
Widget _actionCard(Widget icon, String label, Color iconColor) {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(width: 10),
        icon,
      ],
    ),
  );
}


Widget _analyticsCard(Widget icon, String value, String label, Color iconColor) {
  return Container(
    width: 80,
    height: 90,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black), textAlign: TextAlign.center),
      ],
    ),
  );
}

// Helper method for slot status analytics box
Widget _slotAnalyticsCard(String availabilityStatus) {
  Color dotColor = Colors.green;
  if (availabilityStatus == 'Filling Up') dotColor = Colors.orange;
  if (availabilityStatus == 'Full') dotColor = Colors.red;
  if (availabilityStatus == 'Unavailable') dotColor = Colors.grey;

  return Container(
    width: 80,
    height: 90,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24, // Increased width to accommodate the image
          height: 24, // Increased height to accommodate the image
          child: Image.asset(
            'lib/assets/owner/slot.png',
            color: dotColor,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Slot', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        Text(availabilityStatus.split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.black)),
      ],
    ),
  );
}
}