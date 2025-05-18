import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/User/home_screen.dart'; // Import HomeScreen
import 'dart:async'; // Import the dart:async library

class SetUserInfoScreen extends StatefulWidget {
  const SetUserInfoScreen({super.key});

  @override
  _SetUserInfoScreenState createState() => _SetUserInfoScreenState();
}

class _SetUserInfoScreenState extends State<SetUserInfoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showForm = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController(); // Add OTP controller
  final _confirmEmailController = TextEditingController(); // Add controller for confirming email

  bool _isEmailVerified = false; // Track email verification status
  bool _isVerifyingOtp = false; // Track if OTP is being verified

  Timer? _timer; // Add a Timer variable

  final List<Map<String, String>> slides = [
    {
      'image': 'lib/assets/user/slides/first.png',
      'title': 'Welcome to Laundry Scout',
      'description': 'your go-to app for finding and choosing the perfect laundry service, tailored just for you!',
    },
    {
      'image': 'lib/assets/user/slides/second.png',
      'title': 'Effortlessly locate nearby laundry shops',
      'description': 'explore their services, and find exactly what you need, all in one place.',
    },
    {
      'image': 'lib/assets/user/slides/third.png',
      'title': 'Customize your search with filters, view ratings',
      'description': 'and enjoy a smooth, convenient laundry experience right at your fingertips!',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Fetch and pre-fill the user's email if available
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
      // Check if email is already confirmed (optional, but good practice)
      // Supabase user metadata might contain email_confirmed_at
      // For simplicity, we'll assume verification is needed here regardless
    }

    // Start the auto-slide timer
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        // If on the last page, stop the timer and show the form
        timer.cancel();
        if (mounted) { // Check if the widget is still mounted before calling setState
           setState(() {
             _showForm = true;
           });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _otpController.dispose(); // Dispose OTP controller
    _confirmEmailController.dispose(); // Dispose confirm email controller
    _timer?.cancel(); // Cancel the timer in dispose
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // If on the last page, cancel the timer and show the form
      _timer?.cancel();
      setState(() {
        _showForm = true;
      });
    }
  }

  void _skipSlides() {
    // Cancel the timer when skipping slides
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


  Future<void> _submitUserInfo() async {
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
      // Get current user ID again (though already fetched, good for clarity)
      // final user = Supabase.instance.client.auth.currentUser; // Already defined above
      // if (user == null) { // Already checked above
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('User not logged in')),
      //   );
      //   return;
      // }

      try {
        // Upsert the data into the user_profiles table
        // Upsert will insert if the row doesn't exist, or update if it does, based on the 'id'
        await Supabase.instance.client
            .from('user_profiles') // Changed from 'profiles' to 'user_profiles'
            .upsert({
              'id': user.id, // Ensure 'id' is included for upsert to identify the row
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'mobile_number': _mobileNumberController.text.trim(),
              // 'updated_at': DateTime.now().toIso8601String(), // Supabase trigger handles this
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          // Navigate to HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${error.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Add this line
        title: const Text(''), // Empty title
        actions: _showForm
            ? null // No actions on the form page
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
      body: _showForm ? _buildProfileForm(textTheme) : _buildSlides(textTheme),
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
                      height: 250, // Adjust size as needed
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
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0), // Corrected padding here
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
              if (_currentPage == slides.length - 1)
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF), // White background
                    foregroundColor: const Color(0xFF6F5ADC), // Purple text
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton(
                   onPressed: _nextPage,
                   style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFFFF), // White background
                    foregroundColor: const Color(0xFF6F5ADC), // Purple text
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              _buildTextField(
                controller: _firstNameController,
                labelText: 'First name',
                textTheme: textTheme,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                labelText: 'Last name',
                textTheme: textTheme,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mobileNumberController,
                labelText: 'Mobile Number',
                keyboardType: TextInputType.phone,
                textTheme: textTheme,
              ),
              const SizedBox(height: 16),
               _buildTextField(
                controller: _emailController,
                labelText: 'Email Address', // Changed label slightly
                keyboardType: TextInputType.emailAddress,
                textTheme: textTheme,
                // Removed readOnly: true
                // Removed validator: null
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
                 // Removed the "Send Verification Code" button
                const SizedBox(height: 16), // Keep or adjust spacing as needed
                _buildTextField(
                  controller: _otpController,
                  labelText: 'Verification Code',
                  keyboardType: TextInputType.number,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
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
                 _buildTextField(
                  controller: _confirmEmailController,
                  labelText: 'Confirm Email Address', // Changed label slightly
                  keyboardType: TextInputType.emailAddress,
                  textTheme: textTheme,
                  validator: (value) { // Keep validator for the confirmation field
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your email address';
                    }
                    // The actual matching check is done in _submitUserInfo
                    return null;
                  },
                ),
                const SizedBox(height: 30), // Add space before Submit button
              ],


              // Submit Button (only enabled after verification)
              ElevatedButton(
                onPressed: _isEmailVerified ? _submitUserInfo : null, // Enable only if verified
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEmailVerified ? const Color(0xFFFFFFFF) : Colors.grey, // White background when enabled, grey when disabled
                  foregroundColor: _isEmailVerified ? const Color(0xFF6F5ADC) : Colors.white, // Purple text when enabled, white when disabled
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required TextTheme textTheme,
    bool readOnly = false, // Add readOnly parameter
    String? Function(String?)? validator, // Add validator parameter
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly, // Use the readOnly parameter
      validator: validator, // Use the validator parameter
      style: textTheme.bodyLarge?.copyWith(color: Colors.white), // Set text color to white
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        border: OutlineInputBorder( // Completed InputDecoration
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        enabledBorder: OutlineInputBorder( // Add enabled border style
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder( // Add focused border style
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white), // Highlight color when focused
        ),
        errorBorder: OutlineInputBorder( // Add error border style
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.redAccent), // Error color
        ),
        focusedErrorBorder: OutlineInputBorder( // Add focused error border style
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red), // Focused error color
        ),
        filled: true, // Add filled property
        fillColor: Colors.white.withOpacity(0.1), // Add fill color
      ),
    );
  }
}