import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/User/home_screen.dart';
import 'dart:async';
import '../../services/form_persistence_service.dart';

class SetUserInfoScreen extends StatefulWidget {

  final String username;
  final String email;

  const SetUserInfoScreen({super.key, required this.username, required this.email});

  @override
  _SetUserInfoScreenState createState() => _SetUserInfoScreenState();
}

class _SetUserInfoScreenState extends State<SetUserInfoScreen> {
  final PageController _pageController = PageController();
  late int _currentPage;
  bool _showForm = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();




  Timer? _timer;


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
    
    final user = Supabase.instance.client.auth.currentUser;
    _emailController.text = widget.email;
    _usernameController.text = widget.username;
    if (user != null && user.email != null && _emailController.text.isEmpty) {
      _emailController.text = user.email!;
    }
    _currentPage = 0;

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
    _mobileNumberController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
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


  Future<void> _submitUserInfo() async {
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }


    if (_formKey.currentState!.validate()) {
     
      try {
        
        await Supabase.instance.client
            .from('user_profiles') 
            .upsert({
              'id': user.id, 
              'username': widget.username, 
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'mobile_number': _mobileNumberController.text.trim(),
              'email': _emailController.text.trim(), 
            });

        if (mounted) {
          
          await FormPersistenceService.clearUserInfoData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          
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
        automaticallyImplyLeading: false,
        title: const Text(''),
        actions: _showForm
            ? null 
            : [
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    
                    bool isMobile = MediaQuery.of(context).size.width < 600;
                    
                    if (isMobile) {
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A35E3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: _skipSlides,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    } else {
                     
                      return TextButton(
                        onPressed: _skipSlides,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                  },
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
                    backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A35E3),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, decoration: TextDecoration.none),
                  ),
                )
              else
                ElevatedButton(
                   onPressed: _nextPage,
                   style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A35E3),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, decoration: TextDecoration.none),
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
                 validator: (value) {
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
              const SizedBox(height: 16), 

            
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A35E3),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, decoration: TextDecoration.none),
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
    bool readOnly = false, 
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly, 
      validator: validator, 
      style: textTheme.bodyLarge?.copyWith(color: Colors.white), 
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        enabledBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white), 
        ),
        errorBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.redAccent), 
        ),
        focusedErrorBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}