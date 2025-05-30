import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_screen.dart';
import 'profile_screen.dart'; // Import the new profile screen

// Convert StatelessWidget to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User'; // Default name
  bool _isLoading = true;
  List<Map<String, dynamic>> _laundryShops = []; // State variable to hold laundry shops
  List<Map<String, dynamic>> _promos = []; // State variable to hold promo data

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadLaundryShops(); // Load laundry shops when the screen initializes
    _loadPromos(); // Load promos when the screen initializes
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // If user is not logged in, navigate to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Fetch user profile from 'user_profiles' table
      // Assuming 'user_profiles' table has 'id' and 'username' columns
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('username') // Select the username column
          .eq('id', user.id)
          .single(); // Expecting a single row for the current user

      if (mounted) {
        setState(() {
          // Update the username if found, otherwise keep default
          _userName = response['username'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors (e.g., profile not found, network issues)
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optionally show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: $e')),
        );
      }
    }
  }

  // New method to load laundry shops from Supabase
  Future<void> _loadLaundryShops() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name, exact_location, cover_photo_url, does_delivery'); // Select relevant columns

      if (mounted) {
        setState(() {
          _laundryShops = List<Map<String, dynamic>>.from(response); // Cast response to the correct type
        });
      }
    } catch (e) {
      print('Error loading laundry shops: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading laundry shops: $e')),
        );
      }
    }
  }

  // New method to load promos from Supabase
  Future<void> _loadPromos() async {
    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*, business_profiles(business_name)'); // Select all columns from the promos table and join business_profiles to get business_name

      if (mounted) {
        setState(() {
          _promos = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error loading promos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a Stack to place the bottom navigation bar above the body content
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Background color from image
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Welcome, Name, Profile Picture, Filter Icon
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6F5ADC), // Purple background
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    _userName, // Display fetched username
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Profile Picture (Placeholder) - Make it tappable
                              GestureDetector( // Wrap with GestureDetector
                                onTap: () {
                                  // Navigate to the ProfileScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, color: Color(0xFF6F5ADC)), // Placeholder icon
                                  // TODO: Load actual user profile picture if available
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Search Bar and Filter Icon
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search Here',
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
                                child: const Icon(Icons.filter_list, color: Color(0xFF6F5ADC)), // Filter icon
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Active Orders Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Placeholder for Delivery Icon
                          Column(
                            children: [
                              Icon(Icons.delivery_dining, size: 40, color: Colors.grey[700]),
                              const SizedBox(height: 4),
                              Text('Pick Up', style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          // Active Orders Count
                          Column(
                            children: [
                              Icon(Icons.assignment, size: 40, color: Colors.grey[700]),
                              const SizedBox(height: 4),
                              const Text('0 Active orders', style: TextStyle(color: Colors.black)), // Placeholder count
                            ],
                          ),
                          // Placeholder for Delivery Truck Icon
                          Column(
                            children: [
                              Icon(Icons.local_shipping, size: 40, color: Colors.grey[700]),
                              const SizedBox(height: 4),
                              Text('Delivery', style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Promos Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Promos',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Horizontal list of promos
                    SizedBox(
                      height: 150, // Adjust height as needed
                      child: _promos.isEmpty
                          ? const Center(child: Text('No promos available.'))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: false,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _promos.length,
                              itemBuilder: (context, index) {
                                final promo = _promos[index];
                                final businessName = promo['business_profiles']?['business_name'] ?? 'Unknown Business';
                                print('Promo Image URL for ${promo['title']}: ${promo['image_url']}'); // Add this line
                                return Container(
                                  width: 250, // Adjust width as needed
                                  margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == _promos.length - 1 ? 16.0 : 0),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent, // Placeholder color
                                    borderRadius: BorderRadius.circular(15),
                                    image: promo['image_url'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(promo['image_url']),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            image: AssetImage('lib/assets/promo_placeholder.png'), // Fallback placeholder image
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: Container(
                                    // Optional: Add a gradient overlay for better text readability
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    
                                        Text(
                                          'By: $businessName',
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    // Nearest Laundry Shop's Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Nearest Laundry Shop's",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement View All action
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(color: Color(0xFF6F5ADC)), // Purple color
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Horizontal list of laundry shops
                    SizedBox(
                      height: 200, // Defines the height of the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: false,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _laundryShops.length,
                        itemBuilder: (context, index) {
                          final shop = _laundryShops[index]; // Get the current shop data
                          // TODO: Replace with actual Laundry Shop Card widget
                          return Container(
                            width: 180, // Adjust width as needed
                            margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == _laundryShops.length - 1 ? 16.0 : 0), // Adjust margin based on list length
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Placeholder Image - Use actual cover photo if available
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    image: shop['cover_photo_url'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(shop['cover_photo_url']), // Use fetched image URL
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage( // Fallback placeholder image
                                            image: AssetImage('lib/assets/laundry_placeholder.png'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop['business_name'] ?? 'Laundry Shop',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87, // More visible color
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shop['exact_location'] ?? 'Address Placeholder', // Use fetched location
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // Placeholder status indicator - You might need to add a status field to business_profiles
                                          Icon(Icons.circle, size: 10, color: shop['does_delivery'] == true ? Colors.green : Colors.orange), // Example: Use does_delivery for status
                                          const SizedBox(width: 4),
                                          Text(
                                            shop['does_delivery'] == true ? 'Delivery Available' : 'No Delivery', // Example status text
                                            style: TextStyle(fontSize: 12, color: shop['does_delivery'] == true ? Colors.green : Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80), // Add padding at the bottom to make space for the bottom nav bar
                  ],
                ),
              ),
            ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedItemColor: const Color(0xFF6F5ADC), // Purple selected color
        unselectedItemColor: Colors.grey, // Grey unselected color
        backgroundColor: Colors.white, // White background
        currentIndex: 0, // Assuming Home is the first item
        onTap: (index) {
          // TODO: Implement navigation for other tabs
          if (index == 0) {
            // Stay on Home
          } else if (index == 4) {
             // Handle Notification tap - maybe show a dialog or navigate
             // For now, let's just print
             print('Notification tapped');
          }
          // Add logic for other tabs (Location, Laundry, Messages)
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_laundry_service),
            label: 'Laundry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
      ),
    );
  }
}