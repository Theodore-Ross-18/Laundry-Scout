import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../splash/splash_screen.dart'; // Changed import to splash screen
import '../../auth/login_screen.dart'; // Assuming login_screen.dart is in this path
import '../../../widgets/optimized_image.dart';
import '../../../services/image_service.dart';
import '../Owner/owner_notification_screen.dart'; // Import the OwnerNotificationScreen
import 'image_preview_screen.dart'; // Import the ImagePreviewScreen

// Helper function for creating a fade transition (copied from login_screen.dart)
Route _createFadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Use FadeTransition for a fade-in/fade-out effect
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300), // Adjust duration as needed
  );
}

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
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
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
      // Assuming 'user_profiles' table has 'id', 'first_name', 'last_name', 'email', 'mobile_number', and 'profile_image_url' columns
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('first_name, last_name, email, mobile_number, profile_image_url') // Added profile_image_url
          .eq('id', user.id)
          .single(); // Expecting a single row for the current user

      if (mounted) {
        setState(() {
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _email = response['email'] ?? user.email ?? ''; // Use Supabase auth email if profile email is null
          _phoneNumber = response['mobile_number'] ?? ''; // Changed phone_number to mobile_number
          _profileImageUrl = response['profile_image_url'];
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

  Future<void> _pickAndUploadImage() async {
    try {
      // Pick image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final user = Supabase.instance.client.auth.currentUser;
        
        if (user == null) return;

        // Compress the image using ImageService
        final compressedBytes = await ImageService.compressImage(
          result.files.single.bytes!,
        );

        // Create unique filename
        final fileExt = result.files.single.extension ?? 'jpg';
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'profile_images/$fileName';

        // Upload compressed image to Supabase Storage
        await Supabase.instance.client.storage
            .from('profiles')
            .uploadBinary(filePath, compressedBytes);

        // Get public URL
        final imageUrl = Supabase.instance.client.storage
            .from('profiles')
            .getPublicUrl(filePath);

        // Update user profile with new image URL
        await Supabase.instance.client
            .from('user_profiles')
            .update({'profile_image_url': imageUrl})
            .eq('id', user.id);

        // Update local state
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      print('Error uploading image: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createFadeRoute(const SplashScreen()), // Navigate to splash screen instead
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
                        child: Stack(
                          children: [
                            ProfileImageWidget(
                              imageUrl: _profileImageUrl ?? '',
                              radius: 50,
                              onTap: () {
                                if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ImagePreviewScreen(
                                        imageUrl: _profileImageUrl!,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6F5ADC),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: _isUploadingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          ],
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
                      // Settings Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add Push Notifications tile
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(_createFadeRoute(const OwnerNotificationScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.notifications_none, color: Color(0xFF6C757D), size: 20),
                              SizedBox(width: 16),
                              Text(
                                'Push Notifications',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.chevron_right, color: Color(0xFF6C757D), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
      // Bottom Navigation Bar removed as requested
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