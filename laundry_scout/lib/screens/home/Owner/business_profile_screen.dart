import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      backgroundColor: const Color(0xFFF8F8F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businessProfile == null
              ? const Center(child: Text('No business profile found', style: TextStyle(color: Colors.black)))
              : SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: CircleAvatar(
                                backgroundColor: Color(0xFF7B61FF).withOpacity(0.15),
                                child: Icon(Icons.arrow_back, color: Color(0xFF7B61FF)),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Business Profile',
                                  style: TextStyle(
                                    color: Color(0xFF7B61FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Avatar
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.grey[200],
                        child: _businessProfile!["avatar_url"] != null
                            ? ClipOval(
                                child: Image.network(
                                  _businessProfile!["avatar_url"],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.person, size: 80, color: Color(0xFF7B61FF)),
                      ),
                      SizedBox(height: 24),
                      // Profile Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: (_businessProfile!["business_name"] ?? "Business Name"),
                                  style: TextStyle(
                                    color: Color(0xFF7B61FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text: "'s Profile",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // Edit Profile Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: 'Edit Business Profile',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      // Settings
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _settingsTile('Change Email & Password', Icons.email_outlined),
                            SizedBox(height: 12),
                            _settingsTile('Push Notifications', Icons.notifications_none),
                          ],
                        ),
                      ),
                      Spacer(),
                      // Sign Out Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7B61FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          ),
                          child: Text(
                            'Sign Out',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _settingsTile(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(label, style: TextStyle(color: Colors.black)),
        trailing: icon == Icons.notifications_none ? Icon(Icons.notifications_none, color: Colors.black54) : null,
        onTap: () {},
      ),
    );
  }
}