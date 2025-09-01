import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import '../home/User/home_screen.dart';
import '../home/Owner/owner_home_screen.dart'; 
// Consider importing a package for social icons like font_awesome_flutter
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'forgotpassverify_screen.dart'; // Import the new screen
import 'dart:async'; // Import the dart:async library

// Helper function for creating a fade transition
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // Added for password visibility

  // Add slide-related variables
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSlides = false;
  String? _userType; // 'user' or 'business'
  Timer? _timer; // Add a Timer variable

  // Define slides for different user types
  List<Map<String, String>> get userSlides => [
    {
      'image': 'lib/assets/user/slides/first.png',
      'title': 'Welcome Back to Laundry Scout',
      'description': 'Ready to find the perfect laundry service tailored just for you!',
    },
    {
      'image': 'lib/assets/user/slides/second.png',
      'title': 'Discover Nearby Laundry Shops',
      'description': 'Explore services, compare prices, and find exactly what you need.',
    },
    {
      'image': 'lib/assets/user/slides/third.png',
      'title': 'Enjoy Seamless Experience',
      'description': 'Filter, rate, and book your laundry services with ease!',
    },
  ];

  List<Map<String, String>> get businessSlides => [
    {
      'image': 'lib/assets/user/slides/first.png',
      'title': 'Welcome Back, Business Owner',
      'description': 'Manage your laundry business and connect with more customers!',
    },
    {
      'image': 'lib/assets/user/slides/second.png',
      'title': 'Grow Your Business', 
      'description': 'Update your services, manage bookings, and track your performance.',
    },
    {
      'image': 'lib/assets/user/slides/third.png',
      'title': 'Reach More Customers',
      'description': 'Expand your reach and build lasting relationships with clients!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel(); // Cancel the timer in dispose
    super.dispose();
  }

  void _startSlideTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final slides = _userType == 'business' ? businessSlides : userSlides;
      if (_currentPage < slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        // If on the last page, stop the timer and navigate to home
        timer.cancel();
        _navigateToHome();
      }
    });
  }

  void _nextPage() {
    final slides = _userType == 'business' ? businessSlides : userSlides;
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // If on the last page, navigate to home
      _navigateToHome();
    }
  }

  void _skipSlides() {
    // Cancel the timer when skipping slides
    _timer?.cancel();
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      if (_userType == 'business') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final identifier = _emailController.text.trim();
        final password = _passwordController.text;
        String? emailToSignIn;
        // Add a variable to track the profile type found
        String? profileType; // 'user' or 'business'

        // Check if the input is likely an email
        if (identifier.contains('@')) {
          emailToSignIn = identifier;
          // If it's an email, we'll need to query after successful auth
          // to determine the profile type, or handle this differently.
          // For now, let's assume email login defaults to user profile
          // unless we add a separate flow or check after auth.
          // A more robust solution might involve querying both tables by email
          // or adding a 'type' column to the auth.users table if possible.
          // For this fix, we'll proceed with email sign-in and then check profile.
        } else {
          // Assume it's a username, query the user_profiles table first
          final userProfileResponse = await Supabase.instance.client
              .from('user_profiles')
              .select('email')
              .eq('username', identifier)
              .maybeSingle();

          if (userProfileResponse != null && userProfileResponse.isNotEmpty) {
            emailToSignIn = userProfileResponse['email'] as String?;
            profileType = 'user'; // Found in user_profiles
          } else {
            // Username not found in user_profiles, check business_profiles
            final businessProfileResponse = await Supabase.instance.client
                .from('business_profiles') // Assuming your business table is named 'business_profiles'
                .select('email')
                .eq('username', identifier)
                .maybeSingle();

            if (businessProfileResponse != null && businessProfileResponse.isNotEmpty) {
              emailToSignIn = businessProfileResponse['email'] as String?;
              profileType = 'business'; // Found in business_profiles
            } else {
              // Username not found in either table
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username not found in user or business profiles')),
                );
              }
              setState(() {
                _isLoading = false;
              });
              return; // Stop the sign-in process
            }
          }
        }

        // Proceed with sign-in using the determined email
        if (emailToSignIn != null) {
          final authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: emailToSignIn,
            password: password,
          );

          if (authResponse.user != null) {
            // --- Start of added/modified logic ---
            // If the login was via username, we already know the profile type.
            // If the login was via email, we need to query the profiles table
            // using the authenticated user's ID to determine the type.
            if (profileType == null) {
               // Login was likely via email. Query profiles to find the type.
               final userId = authResponse.user!.id;

               final userProfileCheck = await Supabase.instance.client
                  .from('user_profiles')
                  .select('id') // Select any column, just checking for existence
                  .eq('id', userId)
                  .maybeSingle();

               if (userProfileCheck != null && userProfileCheck.isNotEmpty) {
                  profileType = 'user';
               } else {
                  final businessProfileCheck = await Supabase.instance.client
                     .from('business_profiles')
                     .select('id') // Select any column
                     .eq('id', userId)
                     .maybeSingle();

                  if (businessProfileCheck != null && businessProfileCheck.isNotEmpty) {
                     profileType = 'business';
                  } else {
                     // Should not happen if user exists in auth.users but not in profiles
                     // Handle this edge case if necessary, maybe log out or show error
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('User profile not found after login.')),
                        );
                        // Optionally sign out the user if profile is missing
                        await Supabase.instance.client.auth.signOut();
                     }
                     setState(() { _isLoading = false; });
                     return;
                  }
               }
            }

            // Show slides based on the determined profile type
            if (mounted) {
              setState(() {
                _userType = profileType;
                _showSlides = true;
                _isLoading = false;
              });
              _startSlideTimer();
            }
            // --- End of added/modified logic ---

          }
          // Supabase signInWithPassword automatically throws AuthException on failure
        } else {
           // This case should ideally not be reached if username lookup failed
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not determine email for login')),
              );
            }
        }

      } on AuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      } catch (error) {
        // This catch block will now primarily handle errors from maybeSingle()
        // if multiple rows are returned, or other unexpected issues.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: ${error.toString()}')), // Added error details for debugging
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _showSlides ? AppBar(
        automaticallyImplyLeading: false,
        title: const Text(''),
        actions: [
          // Responsive Skip button with View All design
          LayoutBuilder(
            builder: (context, constraints) {
              // Check if screen width is small (mobile)
              bool isMobile = MediaQuery.of(context).size.width < 600;
              
              if (isMobile) {
                // For mobile: Use a more compact button
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5ADC),
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
                // For larger screens: Use the original TextButton
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
      ) : null,
      body: _showSlides ? _buildSlides(textTheme) : _buildLoginForm(textTheme),
    );
  }

  Widget _buildLoginForm(TextTheme textTheme) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'lib/assets/lslogo.png',
                  height: 76,
                  width: 76,
                ),
                const SizedBox(height: 20),
                Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 298,
                    height: 57,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Username or email',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        suffixIcon: _emailController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18.0),
                                onPressed: () {
                                  setState(() {
                                    _emailController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or username';
                        }
                        return null;
                      },
                      style: textTheme.bodyLarge,
                      onChanged: (text) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    width: 298,
                    height: 57,
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                        ),
                        suffixIcon: _passwordController.text.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18.0, color: Colors.white70),
                                    onPressed: () {
                                      setState(() {
                                        _passwordController.clear();
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      size: 18.0,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      style: textTheme.bodyLarge,
                      onChanged: (text) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 298,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordVerifyScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            decoration: TextDecoration.underline,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF543CDC),
                      foregroundColor: Colors.white,
                      fixedSize: const Size(120, 52),
                      textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Or sign in With',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(
                      child: Image.asset('lib/assets/fb.png', height: 24, width: 24),
                      onPressed: () {
                        // TODO: Implement Facebook Sign-In
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildSocialIcon(
                      child: Image.asset('lib/assets/google.png', height: 24, width: 24),
                      onPressed: () {
                        // TODO: Implement Google Sign-In
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an Account? ",
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          _createFadeRoute(const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlides(TextTheme textTheme) {
    final slides = _userType == 'business' ? businessSlides : userSlides;
    
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
              if (_currentPage == slides.length - 1)
                ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5ADC),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    _userType == 'business' ? 'Start Managing' : 'Get Started',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton(
                   onPressed: _nextPage,
                   style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5ADC),
                    foregroundColor: const Color(0xFFFFFFFF),
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

  Widget _buildSocialIcon({required Widget child, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            )
          ]
        ),
        child: child,
      ),
    );
  }
}