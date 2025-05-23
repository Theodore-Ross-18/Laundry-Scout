import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_screen.dart';

// Convert StatelessWidget to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User'; // Default name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
                              // Profile Picture (Placeholder)
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person, color: Color(0xFF6F5ADC)), // Placeholder icon
                                // TODO: Load actual user profile picture if available
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
                    // Horizontal list of promos (Placeholder)
                    SizedBox(
                      height: 150, // Adjust height as needed
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3, // Placeholder item count
                        itemBuilder: (context, index) {
                          // TODO: Replace with actual Promo Card widget
                          return Container(
                            width: 250, // Adjust width as needed
                            margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == 2 ? 16.0 : 0),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent, // Placeholder color
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: AssetImage('lib/assets/promo_placeholder.png'), // Placeholder image
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Promo ${index + 1}',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                    // Horizontal list of laundry shops (Placeholder)
                    SizedBox(
                      height: 200, // Adjust height as needed
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5, // Placeholder item count
                        itemBuilder: (context, index) {
                          // TODO: Replace with actual Laundry Shop Card widget
                          return Container(
                            width: 180, // Adjust width as needed
                            margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == 4 ? 16.0 : 0),
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
                                // Placeholder Image
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    image: DecorationImage(
                                      image: AssetImage('lib/assets/laundry_placeholder.png'), // Placeholder image
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
                                        'Laundry Shop ${index + 1}', // Placeholder name
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Address Placeholder', // Placeholder address
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.circle, size: 10, color: index.isEven ? Colors.green : Colors.orange), // Placeholder status indicator
                                          const SizedBox(width: 4),
                                          Text(
                                            index.isEven ? 'Open Slots' : 'Filling Up', // Placeholder status text
                                            style: TextStyle(fontSize: 12, color: index.isEven ? Colors.green : Colors.orange),
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