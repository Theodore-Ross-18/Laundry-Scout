import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_screen.dart'; // Assuming login_screen.dart is in this path

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phoneNumber = '';
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
      // Assuming 'user_profiles' table has 'id', 'first_name', 'last_name', 'email', and 'mobile_number' columns
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('first_name, last_name, email, mobile_number') // Select required columns, changed phone_number to mobile_number
          .eq('id', user.id)
          .single(); // Expecting a single row for the current user

      if (mounted) {
        setState(() {
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _email = response['email'] ?? user.email ?? ''; // Use Supabase auth email if profile email is null
          _phoneNumber = response['mobile_number'] ?? ''; // Changed phone_number to mobile_number
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Background color from image
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F5ADC), // Purple background
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        title: const Text(
          'Laundry Scout',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300], // Placeholder background
                          child: Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]), // Placeholder icon
                          // TODO: Implement logic to display actual profile picture
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileField('First Name', _firstName),
                      _buildDivider(),
                      _buildProfileField('Last Name', _lastName),
                      _buildDivider(),
                      _buildProfileField('Email', _email),
                      _buildDivider(),
                      _buildProfileField('Phone Number', _phoneNumber),
                      const SizedBox(height: 40),
                      // Log Out Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6F5ADC), // Purple background
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Add padding for bottom nav bar
                    ],
                  ),
                ),
              ),
            ),
      // Bottom Navigation Bar (Copied from Home Screen)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedItemColor: const Color(0xFF6F5ADC), // Purple selected color
        unselectedItemColor: Colors.grey, // Grey unselected color
        backgroundColor: Colors.white, // White background
        currentIndex: 0, // You might want to manage the selected index state
        onTap: (index) {
          // TODO: Implement navigation logic for other tabs
          // This will require a navigation system (e.g., GoRouter, Navigator)
          // For now, this is just a placeholder.
          print('Tapped item $index');
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

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Adjust width as needed for labels
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 20, thickness: 1, color: Colors.black12);
  }
}