import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../users/set_businessprofile.dart';
import '../../auth/login_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  Map<String, dynamic>? _businessProfile;
  bool _isLoading = true;

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
          SnackBar(content: Text('Error loading profile: \$e')),
        );
      }
    }
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
                                    color: Color(0xFF7B61FF),
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
                                      color: Color(0xFF7B61FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),
                        
                        // Avatar Section
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB8A9FF),
                                Color(0xFF7B61FF),
                              ],
                            ),
                          ),
                          child: _businessProfile!["cover_photo_url"] != null
                              ? ClipOval(
                                  child: Image.network(
                                    _businessProfile!["cover_photo_url"],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                        
                        SizedBox(height: 32),
                        
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
                                ),
                              ),
                              TextSpan(
                                text: "'s Profile",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Edit Profile Button
                         GestureDetector(
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => SetBusinessProfileScreen(
                                   username: _businessProfile!["business_name"] ?? "Business",
                                   businessName: _businessProfile!["business_name"] ?? "",
                                   exactLocation: _businessProfile!["exact_location"] ?? "",
                                 ),
                               ),
                             );
                           },
                           child: Container(
                             width: double.infinity,
                             padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                             decoration: BoxDecoration(
                               color: Color(0xFFF8F9FA),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Color(0xFFE9ECEF), width: 1),
                             ),
                             child: Text(
                               'Edit Business Profile',
                               style: TextStyle(
                                 color: Color(0xFF6C757D),
                                 fontSize: 16,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ),
                        
                        SizedBox(height: 40),
                        
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
                        
                        SizedBox(height: 16),
                        
                        // Settings Items
                        _modernSettingsTile('Change Email & Password', Icons.email_outlined),
                        SizedBox(height: 12),
                        _modernSettingsTile('Push Notifications', Icons.notifications_none, hasTrailing: true),
                        
                        Spacer(),
                        
                        // Sign Out Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7B61FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
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
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _modernSettingsTile(String title, IconData icon, {bool hasTrailing = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6C757D), size: 20),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          if (hasTrailing)
            Icon(Icons.notifications_none, color: Color(0xFF6C757D), size: 20),
        ],
      ),
    );
  }
}