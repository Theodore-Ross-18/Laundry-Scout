import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/optimized_image.dart';
import '../../../widgets/message_badge.dart';
import 'business_profile_screen.dart';
import 'add_promo_screen.dart'; // Import the new screen
import 'owner_message_screen.dart'; // Import the new message screen
import 'owner_notification_screen.dart'; // Import the new notification screen
import 'owner_feedback_screen.dart'; // Import the feedback screen
import 'edit_profile_screen.dart'; // Import the edit profile screen
import 'availability_screen.dart'; // Import the availability screen
import 'orders_screen.dart'; // Import the orders screen
import '../../../services/feedback_service.dart'; // Import FeedbackService
import 'add_branch_screen.dart'; // Import the new screen
import 'add_staff_screen.dart'; // Import the new screen

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
    // _loadReviewStats(); // Removed as it's now called after _loadBusinessProfile
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
          });
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', businessId) // Use the fetched businessId
          .single();

      if (mounted) {
        setState(() {
          _businessProfile = response;
          _isLoading = false;
        });
        _loadReviewStats(); // Load review stats after business profile is loaded
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
        print('Promo count: $_promoCount'); // Add this line for debugging
      }
    } catch (e) {
      print('Error loading promo stats: $e');
    }
  }

  Future<void> _loadReviewStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _businessProfile == null) return; // Ensure _businessProfile is loaded

      final businessId = _businessProfile!['id'];
      if (businessId == null) {
        print('Business ID is null, cannot load review stats.');
        return;
      }

      // Use FeedbackService to get feedback, which includes user_profiles
      final allFeedback = await _feedbackService.getFeedback(businessId);

      // Filter feedback to only count those with user_profiles
      final filteredFeedback = allFeedback.where((feedback) => feedback['user_profiles'] != null).toList();

      if (mounted) {
        setState(() {
          _reviewCount = filteredFeedback.length;
        });
        print('Review count: $_reviewCount'); // Add this line for debugging
      }
    } catch (e) {
      print('Error loading review stats: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreenContent(); // Your existing home screen content
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
                                      color: Color(0xFF7B61FF),
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
                                child: Icon(Icons.person, color: Color(0xFF7B61FF), size: 32),
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
                            height: 120,
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => const OrdersScreen()),
                                        );
                                      },
                                      child: _analyticsCard(Icons.history, '${_orderStats['total']}', 'Order History', Color(0xFF7B61FF)),
                                    ),
                                    _analyticsCard(Icons.local_offer, '$_promoCount', 'Promos', Color(0xFF7B61FF)),
                                    _analyticsCard(Icons.star_outline, '$_reviewCount', 'Reviews', Color(0xFF7B61FF)),
                                    _slotAnalyticsCard(_businessProfile?['availability_status'] ?? 'Open Slots'),
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
                            // Row 1: Add Promo | Edit Profile
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AddPromoScreen()),
                                      );
                                    },
                                    child: _actionCard(Icons.local_offer, 'Add Promo', Colors.deepPurple),
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
                                    child: _actionCard(Icons.edit, 'Edit Profile', Colors.deepPurple),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Reviews | Set Availability
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const OwnerFeedbackScreen()),
                                      );
                                    },
                                    child: _actionCard(Icons.star_outline, 'Reviews', Colors.deepPurple),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AvailabilityScreen()),
                                      );
                                      // If availability was updated, refresh the business profile
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
                            // Row 3: Add Branch | Add Staff
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AddBranchScreen()),
                                      );
                                    },
                                    child: _actionCard(Icons.add, 'Add Branch', Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AddStaffScreen()),
                                      );
                                    },
                                    child: _actionCard(Icons.person_add, 'Add Staff', Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: user != null 
                ? MessageBadge(
                    userId: user.id,
                    child: const Icon(Icons.message_outlined),
                  )
                : const Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF7B61FF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }


  // Helper method for availability card
  Widget _availabilityCard() {
    return _actionCard(Icons.calendar_today, 'Set Availability', Colors.deepPurple);
  }

// Helper widgets:
Widget _actionCard(IconData icon, String label, Color iconColor) {
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
        Icon(icon, color: iconColor, size: 28),
      ],
    ),
  );
}



// Helper method for analytics box
Widget _analyticsCard(IconData icon, String value, String label, Color iconColor) {
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
        Icon(icon, color: iconColor, size: 24),
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
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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