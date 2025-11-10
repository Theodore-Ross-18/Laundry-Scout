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
  String _username = ''; // Add this line
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _notificationsEnabled = false; // Add this line
  
  // Edit mode state
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Text controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _usernameController; // Add this line
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserProfile();
  }
  
  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _usernameController = TextEditingController(); // Add this line
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose(); // Add this line
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
          .select('first_name, last_name, email, mobile_number, profile_image_url, username') 
          .eq('id', user.id)
          .single(); 

      if (mounted) {
        setState(() {
          _firstName = response['first_name'] ?? '';
          _lastName = response['last_name'] ?? '';
          _email = response['email'] ?? user.email ?? ''; 
          _phoneNumber = response['mobile_number'] ?? '';
          _profileImageUrl = response['profile_image_url'];
          _username = response['username'] ?? ''; // Add this line
          _isLoading = false;
          
          // Update controllers with loaded data
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _phoneNumberController.text = _phoneNumber;
          _usernameController.text = _username; // Add this line
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
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values if canceling
        _firstNameController.text = _firstName;
        _lastNameController.text = _lastName;
        _emailController.text = _email;
        _phoneNumberController.text = _phoneNumber;
        _usernameController.text = _username; // Add this line
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }
  
  Future<void> _saveProfile() async {
    try {
      // Validate password fields if provided
      if (_passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match!')),
            );
          }
          return;
        }
        
        if (_passwordController.text.length < 6) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password must be at least 6 characters!')),
            );
          }
          return;
        }
      }
      
      setState(() {
        _isSaving = true;
      });
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      // Prepare update data
      Map<String, dynamic> updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile_number': _phoneNumberController.text.trim(),
        'username': _usernameController.text.trim(), // Add this line
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Update user profile in database
      await Supabase.instance.client
          .from('user_profiles')
          .update(updateData)
          .eq('id', user.id);
      
      // Update email in auth if changed
      if (_emailController.text != _email) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: _emailController.text.trim()),
        );
      }
      
      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }
      
      // Update local state
      setState(() {
        _firstName = _firstNameController.text.trim();
        _lastName = _lastNameController.text.trim();
        _email = _emailController.text.trim();
        _phoneNumber = _phoneNumberController.text.trim();
        _username = _usernameController.text.trim(); // Add this line
        _isEditing = false;
        _isSaving = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
      print('Error updating profile: $e');
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
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: Colors.white,
              ),
              onPressed: _isSaving ? null : _toggleEditMode,
            ),
        ],
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
                      if (_isEditing) ...[
                        _buildEditableProfileField('Username', _usernameController), // Add this line
                        _buildDivider(),
                        _buildEditableProfileField('First Name', _firstNameController),
                        _buildDivider(),
                        _buildEditableProfileField('Last Name', _lastNameController),
                        _buildDivider(),
                        _buildEditableProfileField('Email', _emailController),
                        _buildDivider(),
                        _buildEditableProfileField('Phone Number', _phoneNumberController),
                        _buildDivider(),
                        _buildPasswordField('Password', _passwordController),
                        _buildDivider(),
                        _buildPasswordField('Confirm Password', _confirmPasswordController),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A35E3),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                            OutlinedButton(
                              onPressed: _isSaving ? null : _toggleEditMode,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                side: const BorderSide(color: Color(0xFF5A35E3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF5A35E3)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildProfileField('Username', _username), // Add this line
                        _buildDivider(),
                        _buildProfileField('First Name', _firstName),
                        _buildDivider(),
                        _buildProfileField('Last Name', _lastName),
                        _buildDivider(),
                        _buildProfileField('Email', _email),
                        _buildDivider(),
                        _buildProfileField('Phone Number', _phoneNumber),
                      ],
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
  
  Widget _buildEditableProfileField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5A35E3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5A35E3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: label.contains('Confirm') ? 'Re-enter new password' : 'Enter new password (optional)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}