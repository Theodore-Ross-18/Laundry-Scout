import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../splash/splash_screen.dart';
import 'changeEPP.dart'; 
import '../../../services/session_service.dart'; // Corrected Import SessionService
// import 'owner_notification_screen.dart'; 
import 'image_preview_screen.dart'; 
import 'business_docs_screen.dart'; 

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

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  Map<String, dynamic>? _businessProfile;
  bool _isLoading = true;
  bool _notificationsEnabled = false; // Add this line

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*, owner_push_notif')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _businessProfile = response;
          _notificationsEnabled = response['owner_push_notif'] ?? false;
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

  Future<void> _updateNotificationPreference(bool value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('business_profiles')
          .update({'owner_push_notif': value})
          .eq('id', user.id);

      setState(() {
        _notificationsEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Push notifications ${value ? 'enabled' : 'disabled'})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notification preference: $e')),
        );
      }
      print('Error updating notification preference: $e');
    }
  }

  void _signOut() async {
    try {
      // Update owner_is_online to FALSE before signing out
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        print('Updating owner_is_online to FALSE for user: ${user.id}');
        final updateResult = await Supabase.instance.client
            .from('business_profiles')
            .update({'owner_is_online': false})
            .eq('id', user.id);
        print('Owner offline status updated successfully: $updateResult');
      }
      
      await Supabase.instance.client.auth.signOut();
      SessionService().resetFeedbackFlags();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          _createFadeRoute(const SplashScreen()),
          (route) => false,
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

  Widget _modernSettingsTile(String title, IconData icon, {bool hasTrailing = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE9ECEF), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF6C757D), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Spacer(),
            if (hasTrailing)
              Icon(Icons.chevron_right, color: Color(0xFF6C757D), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businessProfile == null
              ? const Center(child: Text('No business profile found', style: TextStyle(color: Colors.black)))
              : SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Top Bar
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 40),
                            child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF5A35E3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Business Profile',
                                    style: TextStyle(
                                      color: Color(0xFF5A35E3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFA693E3),
                                Color(0xFF5A35E3),
                              ],
                            ),
                          ),
                          child: _businessProfile!["cover_photo_url"] != null
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ImagePreviewScreen(
                                          imageUrl: _businessProfile!["cover_photo_url"],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: _businessProfile!["cover_photo_url"], // Use the image URL as the hero tag
                                    child: ClipOval(
                                      child: Image.network(
                                        _businessProfile!["cover_photo_url"],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Profile Name
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (_businessProfile!["business_name"] ?? "Don Ernesto"),
                                style: TextStyle(
                                  color: Color(0xFF7B61FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  fontFamily: 'Popins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        
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
                        
                        // Settings Items
                        _modernSettingsTile('Change Email, Phone, and Password', Icons.email_outlined, onTap: () {
                          Navigator.of(context).push(_createFadeRoute(const ChangeEPPScreen()));
                        }),
                        const SizedBox(height: 12),
                        // _modernSettingsTile('Push Notifications', Icons.notifications_none, hasTrailing: true, onTap: () {
                        //   Navigator.of(context).push(_createFadeRoute(const OwnerNotificationScreen()));
                        // }),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFE9ECEF), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_none, color: Color(0xFF6C757D), size: 20),
                              const SizedBox(width: 16),
                              Expanded(
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
                                  _updateNotificationPreference(value);
                                },
                                activeColor: Color(0xFF5A35E3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _modernSettingsTile('Update BIR, Business Permit, Business Cert', Icons.business_center_outlined, hasTrailing: true, onTap: () {
                          Navigator.of(context).push(_createFadeRoute(const BusinessDocsScreen()));
                        }),
                        
                        const SizedBox(height: 40),
                        
                      
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5A35E3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32), 
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
