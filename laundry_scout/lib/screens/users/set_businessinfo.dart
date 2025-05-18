import 'package:flutter/material.dart';
import 'dart:async'; // Import the dart:async library

class SetBusinessInfoScreen extends StatefulWidget {
  const SetBusinessInfoScreen({super.key});

  @override
  _SetBusinessInfoScreenState createState() => _SetBusinessInfoScreenState();
}

class _SetBusinessInfoScreenState extends State<SetBusinessInfoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showForm = false;
  Timer? _timer;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();

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
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        timer.cancel();
        if (mounted) {
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
    _phoneNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
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

  Future<void> _submitBusinessInfo() async {
    if (_formKey.currentState!.validate()) {
      // Handle form submission logic here
      // For example, save to Supabase
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Phone Number: ${_phoneNumberController.text}');
      print('Business Name: ${_businessNameController.text}');
      print('Business Address: ${_businessAddressController.text}');
      // Add logic for file uploads

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business information submitted (placeholder)')),
        );
        // Potentially navigate to a business dashboard or home screen
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
        title: Text(_showForm ? 'Set Up Business Profile' : 'Welcome to Laundry Scout'),
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
              const SizedBox(height: 30),
              _buildFileUploadField(label: 'Attach BIR Registration', textTheme: textTheme),
              const SizedBox(height: 20),
              _buildFileUploadField(label: 'Business Certificate', textTheme: textTheme),
              const SizedBox(height: 20),
              _buildFileUploadField(label: 'Business Mayors Permit', textTheme: textTheme),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitBusinessInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor, // Use theme color
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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