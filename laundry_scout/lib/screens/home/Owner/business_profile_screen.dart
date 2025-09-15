import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../users/set_businessprofile.dart';
import '../../splash/splash_screen.dart';

// Business Feedback Modal for admin feedback
class BusinessFeedbackModal extends StatefulWidget {
  const BusinessFeedbackModal({super.key});

  @override
  State<BusinessFeedbackModal> createState() => _BusinessFeedbackModalState();
}

class _BusinessFeedbackModalState extends State<BusinessFeedbackModal> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 0;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to submit feedback'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // First, get the business ID for this user
      final businessResponse = await Supabase.instance.client
          .from('business_profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final businessId = businessResponse['id'];

      // SQL query to insert business owner feedback
      await Supabase.instance.client.from('feedback').insert({
        'user_id': user.id,
        'business_id': businessId,
        'rating': _rating,
        'comment': _feedbackController.text.trim(),
        'feedback_type': 'business', // Specify this is business feedback
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                'Business Feedback',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your experience as a business owner',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Interactive star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.star,
                        color: index < _rating ? const Color(0xFFFFB800) : Colors.grey[300],
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Feedback text area
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts about the platform...',
                    hintStyle: TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFF9C88FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B61FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitted ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isSubmitted
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function for creating a fade transition (copied from profile_screen.dart)
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
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        _createFadeRoute(const SplashScreen()),
        (route) => false,
      );
    }
  }

  void _showFeedbackModal() {
    showDialog(
      context: context,
      builder: (context) => const BusinessFeedbackModal(),
    );
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
                              const SizedBox(width: 40),
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
                        
                        const SizedBox(height: 24),
                        
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
                             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                        
                        const SizedBox(height: 40),
                        
                        // Feedback Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Feedback',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _modernSettingsTile('Submit Feedback', Icons.feedback_outlined, onTap: () => _showFeedbackModal()),
                        
                        const SizedBox(height: 24),
                        
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
                        _modernSettingsTile('Change Email & Password', Icons.email_outlined),
                        const SizedBox(height: 12),
                        _modernSettingsTile('Push Notifications', Icons.notifications_none, hasTrailing: true),
                        
                        const SizedBox(height: 40),
                        
                        // Sign Out Button
                        Container(
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
                        const SizedBox(height: 32), // Add bottom padding for scroll
                      ],
                    ),
                  ),
                ),
              ),
    );
  } // End of _BusinessProfileScreenState class
} // End of BusinessProfileScreen class
