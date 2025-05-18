import 'package:flutter/material.dart';
import 'dart:async'; // Import the dart:async library
import 'package:supabase_flutter/supabase_flutter.dart'; // Moved this line up
// You'll likely need file_picker and path for file uploads
// import 'package:file_picker/file_picker.dart';
// import 'dart:io'; // For File type
import '../home/Owner/owner_home_screen.dart'; 
class SetBusinessInfoScreen extends StatefulWidget {
  // Add a field to receive the username
  final String username;

  // Update the constructor to require the username
  const SetBusinessInfoScreen({super.key, required this.username});

  @override
  _SetBusinessInfoScreenState createState() => _SetBusinessInfoScreenState();
}

class _SetBusinessInfoScreenState extends State<SetBusinessInfoScreen> {
  // Remove 'final' from the declaration
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showForm = false;
  Timer? _timer;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _emailController = TextEditingController(); // Add email controller
  final _otpController = TextEditingController(); // Add OTP controller
  final _confirmEmailController = TextEditingController(); // Add controller for confirming email

  bool _isEmailVerified = false; // Track email verification status
  bool _isVerifyingOtp = false; // Track if OTP is being verified


  // Copied from set_userinfo.dart - adjust content if needed for business context
  final List<Map<String, String>> slides = [
    {
      'image': 'lib/assets/user/slides/first.png', // Consider business-specific images
      'title': 'Welcome, Business Owner!',
      'description': 'Let\'s get your laundry business set up on Laundry Scout.',
    },
    {
      'image': 'lib/assets/user/slides/second.png',
      'title': 'Showcase Your Services',
      'description': 'Reach new customers and manage your operations efficiently.',
    },
    {
      'image': 'lib/assets/user/slides/third.png',
      'title': 'Grow Your Business',
      'description': 'Join our network and make laundry services more accessible.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // You can access the username here using widget.username
    // For example, to pre-fill a field or display it:
    // _businessNameController.text = widget.username; // Or handle as needed
    // Schedule the timer to show the form after slides
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showForm = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose(); // Dispose email controller
    _otpController.dispose(); // Dispose OTP controller
    _confirmEmailController.dispose(); // Dispose confirm email controller
    _timer?.cancel();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _timer?.cancel();
      setState(() {
        _showForm = true;
      });
    }
  }

  void _skipSlides() {
    _timer?.cancel();
    setState(() {
      _showForm = true;
    });
  }

  // Function to verify OTP
  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim(); // Use the pre-filled email for verification
    final otp = _otpController.text.trim();

    if (email.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and verification code')),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      if (res.user != null) {
        // OTP verification successful
        if (mounted) {
          setState(() {
            _isEmailVerified = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );
        }
      } else {
         // Handle cases where user is null but no exception was thrown (shouldn't happen with verifyOTP usually)
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification failed. Please try again.')),
            );
         }
      }

    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }


  Future<void> _submitBusinessInfo() async {
    // Check if email is verified before submitting
    if (!_isEmailVerified) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email first.')),
        );
        return; // Stop the submission process
    }

    // Get current user ID
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Handle case where user is not logged in (shouldn't happen if flow is correct)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Check if the confirmed email matches the email entered in the email field (which is now pre-filled)
    if (_confirmEmailController.text.trim() != _emailController.text.trim()) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmed email must match your registered email.')),
        );
        return; // Stop the submission process
    }


    if (_formKey.currentState!.validate()) {
      // Placeholder for file upload logic:
      // String? birUrl, certificateUrl, permitUrl;
      // try {
      //   if (_birFile != null) {
      //     final String fileName = 'bir_${user.id}.${_birFile!.path.split('.').last}';
      //     await Supabase.instance.client.storage.from('business_documents').upload(fileName, _birFile!);
      //     birUrl = Supabase.instance.client.storage.from('business_documents').getPublicUrl(fileName);
      //   }
      //   // Repeat for _certificateFile and _permitFile
      // } catch (e) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Error uploading files: ${e.toString()}')),
      //     );
      //   }
      //   return;
      // }


      try {
        await Supabase.instance.client
            .from('business_profiles') // Changed to 'business_profiles'
            .upsert({
              'id': user.id, // Primary key, links to auth.users
              'username': widget.username, // Add the username here
              'owner_first_name': _firstNameController.text.trim(),
              'owner_last_name': _lastNameController.text.trim(),
              'business_name': _businessNameController.text.trim(),
              'business_address': _businessAddressController.text.trim(),
              'business_phone_number': _phoneNumberController.text.trim(),
              // 'bir_registration_url': birUrl,
              // 'business_certificate_url': certificateUrl,
              // 'mayors_permit_url': permitUrl,
              // 'updated_at': DateTime.now().toIso8601String(), // Supabase trigger handles this
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business information submitted successfully!')),
          );
          // Potentially navigate to a business dashboard or home screen
          // For example, back to home or a specific business dashboard:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerHomeScreen()), // Or a BusinessHomeScreen
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting business info: ${error.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // appBar uses theme's scaffoldBackgroundColor by default if not overridden
      appBar: AppBar(
        automaticallyImplyLeading: false, // Add this line
        title: const Text(''), // Empty title
        actions: _showForm
            ? null
            : [
                TextButton(
                  onPressed: _skipSlides,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
      ),
      body: _showForm ? _buildBusinessInfoForm(textTheme) : _buildSlides(textTheme),
    );
  }

  Widget _buildSlides(TextTheme textTheme) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      slides[index]['image']!,
                      height: 250,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      slides[index]['title']!,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slides[index]['description']!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor, // Use theme color
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  _currentPage == slides.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoForm(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'LET\'S GET STARTED',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildFormTextField(
                      controller: _firstNameController,
                      labelText: 'First name',
                      textTheme: textTheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormTextField(
                      controller: _lastNameController,
                      labelText: 'Last name',
                      textTheme: textTheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _phoneNumberController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _businessNameController,
                labelText: 'Business Name',
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _businessAddressController,
                labelText: 'Business Address',
                textTheme: textTheme,
              ),
              const SizedBox(height: 20), // Added spacing
              _buildFormTextField( // Added Email field
                controller: _emailController,
                labelText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                textTheme: textTheme,
                readOnly: false, // Changed from true to false
                validator: (value) { // Added email validator
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    // Basic email format validation
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 30),
              // Email Verification Section
              if (!_isEmailVerified) ...[
                 // Removed the "Send Verification Code" button (Supabase sends automatically on signup)
                const SizedBox(height: 16), // Keep or adjust spacing as needed
                _buildFormTextField( // Added OTP field
                  controller: _otpController,
                  labelText: 'Verification Code',
                  keyboardType: TextInputType.number,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 16),
                ElevatedButton( // Added Verify Code button
                  onPressed: _isVerifyingOtp ? null : _verifyOtp,
                   style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5ADC), // Purple background
                    foregroundColor: const Color(0xFFFFFFFF), // White text
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isVerifyingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 30), // Add space before Submit button
              ],

              // Add Confirm Email field here, after verification section
              if (_isEmailVerified) ...[ // Only show confirm email if email is verified
                 _buildFormTextField( // Added Confirm Email field
                  controller: _confirmEmailController,
                  labelText: 'Confirm Email Address',
                  keyboardType: TextInputType.emailAddress,
                  textTheme: textTheme,
                  validator: (value) { // Keep validator for the confirmation field
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your email address';
                    }
                    // The actual matching check is done in _submitBusinessInfo
                    return null;
                  },
                ),
                const SizedBox(height: 30), // Add space before file uploads
              ],

              // File Upload Fields (only shown after email is verified)
              if (_isEmailVerified) ...[
                _buildFileUploadField(label: 'Attach BIR Registration', textTheme: textTheme),
                const SizedBox(height: 20),
                _buildFileUploadField(label: 'Business Certificate', textTheme: textTheme),
                const SizedBox(height: 20),
                _buildFileUploadField(label: 'Business Mayors Permit', textTheme: textTheme),
                const SizedBox(height: 40),
              ],


              ElevatedButton( // Submit Button (only enabled after verification)
                onPressed: _isEmailVerified ? _submitBusinessInfo : null, // Enable only if verified
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEmailVerified ? Colors.white : Colors.grey, // White background when enabled, grey when disabled
                  foregroundColor: _isEmailVerified ? Theme.of(context).primaryColor : Colors.white, // Use theme color when enabled, white when disabled
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('SUBMIT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required TextTheme textTheme,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      // validator: validator, // Remove this line
      style: textTheme.bodyLarge?.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.redAccent.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
      ),
      // Keep the default validator if none is provided
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }

  Widget _buildFileUploadField({required String label, required TextTheme textTheme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white, // Changed from black87
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Handle file upload tap
            print('$label tapped for upload');
            // Implement file picking logic here
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // Changed from grey[200]
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.white.withOpacity(0.3)), // Added a subtle border
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.white70, // Changed from black54
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click here to upload',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70, // Changed from black54
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}