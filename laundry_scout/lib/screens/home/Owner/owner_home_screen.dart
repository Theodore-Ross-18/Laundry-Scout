import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'business_profile_screen.dart';
import 'add_promo_screen.dart'; // Import the new screen
import 'owner_message_screen.dart'; // Import the new message screen
import 'owner_notification_screen.dart'; // Import the new notification screen
import 'owner_feedback_screen.dart'; // Import the new feedback screen

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  Map<String, dynamic>? _businessProfile;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _businessProfile = response;
          _isLoading = false;
        });
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
      case 3:
        return const OwnerFeedbackScreen();
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
                            Column(
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
                          child: _businessProfile!["cover_photo_url"] != null
                              ? Image.network(
                                  _businessProfile!["cover_photo_url"],
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(Icons.image, size: 48, color: Colors.grey[500]),
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
                                    _statBox(Icons.shopping_bag, '12', 'Orders', Color(0xFF4BE1AB)),
                                    _statBox(Icons.timer, '5', 'Pending', Color(0xFFFF8A71)),
                                    _viewOrdersButton(),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _statBox(Icons.sync, '12', 'On Progress', Color(0xFFFFC542)),
                                    _statBox(Icons.local_shipping, '36', 'Delivered', Color(0xFF3ECFFF)),
                                    SizedBox(width: 80), // To align with View Orders button
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
                                  child: GestureDetector( // Wrap with GestureDetector
                                    onTap: () {
                                      Navigator.of(context).push( // Navigate to AddPromoScreen
                                        MaterialPageRoute(builder: (context) => const AddPromoScreen()),
                                      );
                                    },
                                    child: _actionCard(Icons.percent, 'Add Promo', Colors.deepPurple),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _actionCard(Icons.edit, 'Edit Profile', Colors.deepPurple)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _actionCard(Icons.reviews, 'Reviews', Colors.deepPurple)),
                                const SizedBox(width: 12),
                                Expanded(child: _availabilityCard()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Removed the old navigation items container
                    ],
                  ),
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _buildBody(), // Use the new _buildBody method
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            label: 'Feedback',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF7B61FF), // Purple color for selected item
        unselectedItemColor: Colors.grey, // Grey for unselected
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
        backgroundColor: Colors.white,
        elevation: 8.0, // Add some elevation like in the image
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _viewOrdersButton() {
    return Container(
      width: 80,
      height: 64,
      decoration: BoxDecoration(
        color: Color(0xFF7B61FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text('View Orders', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
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
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    ),
  );
}

Widget _availabilityCard() {
  return Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              Text('Open Slots', style: TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 2),
          Text('Set Availability', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    ),
  );
}

// Widget _navItem(IconData icon, String label, bool selected) {  <-- REMOVE THIS WIDGET
//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Icon(icon, color: selected ? Colors.deepPurple : Colors.black54),
//       Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.deepPurple : Colors.black54, fontSize: 12)),
//     ],
//   );
// }