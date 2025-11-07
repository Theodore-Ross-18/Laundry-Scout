import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../splash/splash_screen.dart';
import '../../auth/login_screen.dart';
import '../../../widgets/optimized_image.dart';
import '../../../services/image_service.dart';
import '../../../services/session_service.dart'; // Import SessionService
// import '../Owner/owner_notification_screen.dart'; 
import 'image_preview_screen.dart'; 


Route _createFadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
    
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300), 
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
  bool _notificationsEnabled = false; // Add this line

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
    
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }
 
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('first_name, last_name, email, mobile_number, profile_image_url') 
          .eq('id', user.id)
          .single(); 

      if (mounted) {
        setState(() {
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _email = response['email'] ?? user.email ?? ''; 
          _phoneNumber = response['mobile_number'] ?? '';
          _profileImageUrl = response['profile_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
 
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

        final compressedBytes = await ImageService.compressImage(
          result.files.single.bytes!,
        );

        final fileExt = result.files.single.extension ?? 'jpg';
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'profile_images/$fileName';

        await Supabase.instance.client.storage
            .from('profiles')
            .uploadBinary(filePath, compressedBytes);

       
        final imageUrl = Supabase.instance.client.storage
            .from('profiles')
            .getPublicUrl(filePath);

      
        await Supabase.instance.client
            .from('user_profiles')
            .update({'profile_image_url': imageUrl})
            .eq('id', user.id);

        
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
      // Update user_is_online to FALSE before signing out
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        print('Updating user_is_online to FALSE for user: ${user.id}');
        final updateResult = await Supabase.instance.client
            .from('user_profiles')
            .update({'user_is_online': false})
            .eq('id', user.id);
        print('User offline status updated successfully: $updateResult');
      }
      
      await Supabase.instance.client.auth.signOut();
      SessionService().resetFeedbackFlags();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          _createFadeRoute(const SplashScreen()), 
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
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A35E3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Laundry Scout',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
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
                                        imageUrls: [_profileImageUrl!],
                                        initialIndex: 0,
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
                                    color: const Color(0xFF5A35E3),
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
                     
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.of(context).push(_createFadeRoute(const OwnerNotificationScreen()));
                      //   },
                      //   child: Container(
                      //     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      //     decoration: BoxDecoration(
                      //       color: const Color(0xFFF8F8F8),
                      //       borderRadius: BorderRadius.circular(12),
                      //       border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      //     ),
                      //     child: const Row(
                      //       children: [
                      //         Icon(Icons.notifications_none, color: Color(0xFF6C757D), size: 20),
                      //         SizedBox(width: 16),
                      //         Text(
                      //           'Push Notifications',
                      //           style: TextStyle(
                      //             color: Colors.black87,
                      //             fontSize: 16,
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         ),
                      //         Spacer(),
                      //         Icon(Icons.chevron_right, color: Color(0xFF6C757D), size: 20),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_none, color: Color(0xFF6C757D), size: 20),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Push Notifications',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: (bool value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                                // Handle notification toggle logic here
                              },
                              activeColor: const Color(0xFF5A35E3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Log Out Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A35E3),
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
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
            width: 120,
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