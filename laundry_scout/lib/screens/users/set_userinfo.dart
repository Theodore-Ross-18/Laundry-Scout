import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart'; // Import HomeScreen

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
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      setState(() {
        _showForm = true;
      });
    }
  }

  void _skipSlides() {
    setState(() {
      _showForm = true;
    });
  }

  Future<void> _submitUserInfo() async {
    if (_formKey.currentState!.validate()) {
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Handle case where user is not logged in (shouldn't happen if flow is correct)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      try {
        // Update the profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'mobile_number': _mobileNumberController.text.trim(),
              'email': _emailController.text.trim(), // Update email if needed
            })
            .eq('id', user.id); // Filter by the current user's ID

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
        title: Text(_showForm ? 'Setting Profile Info' : 'Laundry Scout'),
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
                labelText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                textTheme: textTheme,
                readOnly: true, // Make email field read-only
                 // You might want to pre-fill this with the user's registered email
                 // and potentially make it non-editable if email changes are not allowed here.
                 // For now, it's editable.
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFFFF), // White background
                  foregroundColor: const Color(0xFF6F5ADC), // Purple text
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly, // Use the readOnly parameter
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
        ),
      ),
      validator: readOnly ? null : (value) { // Only validate if not read-only
        if (value == null || value.isEmpty) {
          return 'Please enter your $labelText';
        }
        // Add more specific validation if needed (e.g., email format, phone number format)
        return null;
      },
      style: textTheme.bodyLarge?.copyWith(color: Colors.white),
    );
  }
}