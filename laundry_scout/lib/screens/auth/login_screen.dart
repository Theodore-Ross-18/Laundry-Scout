import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import '../home/User/home_screen.dart';
import '../home/Owner/owner_home_screen.dart'; 
import 'forgotpassverify_screen.dart';
import 'dart:async'; 
import '../../services/notification_service.dart';
import 'package:laundry_scout/widgets/animated_eye_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  bool _obscurePassword = true; 


  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSlides = false;
  String? _userType; 
  Timer? _timer; 

  Future<bool> _shouldShowSlides() async {
  final prefs = await SharedPreferences.getInstance();
  final lastShownStr = prefs.getString('last_intro_shown');

  if (lastShownStr == null) {
    // First time login
    return true;
  }

  final lastShown = DateTime.tryParse(lastShownStr);
  if (lastShown == null) {
    return true;
  }

  final now = DateTime.now();

  // Same day check
  if (now.year == lastShown.year &&
      now.month == lastShown.month &&
      now.day == lastShown.day) {
    return false;
  }

  final difference = now.difference(lastShown).inDays;
  return difference >= 3;
}

Future<void> _setIntroShownDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_intro_shown', DateTime.now().toIso8601String());
}

  
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
    _timer?.cancel(); 
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
      
      _navigateToHome();
    }
  }

  void _skipSlides() {
   
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
        String? profileType;

        if (identifier.contains('@')) {
          emailToSignIn = identifier;
        } else {
            
            final businessProfileUsernameResponse = await Supabase.instance.client
                .from('business_profiles')
                .select('email, username')
                .eq('username', identifier)
                .maybeSingle();

            if (businessProfileUsernameResponse != null && businessProfileUsernameResponse.isNotEmpty) {
              emailToSignIn = businessProfileUsernameResponse['email'] as String?;
              profileType = 'business';
            } else {
              
              final userProfileResponse = await Supabase.instance.client
                .from('user_profiles')
                .select('email')
                .eq('username', identifier)
                .maybeSingle();

              if (userProfileResponse != null && userProfileResponse.isNotEmpty) {
                emailToSignIn = userProfileResponse['email'] as String?;
                profileType = 'user';
              } else {
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username not found in user or business profiles')),
                  );
                }
                setState(() {
                  _isLoading = false;
                });
                return;
              }
            }
          }

        if (emailToSignIn != null) {
          final authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: emailToSignIn,
            password: password,
          );

          if (authResponse.user != null) {
            final userId = authResponse.user!.id;
            String? determinedProfileType = profileType;

            if (determinedProfileType == null) {
              final userProfileCheck = await Supabase.instance.client
                  .from('user_profiles')
                  .select('id')
                  .eq('id', userId)
                  .maybeSingle();

              if (userProfileCheck != null && userProfileCheck.isNotEmpty) {
                determinedProfileType = 'user';
              } else {
                final businessProfileCheck = await Supabase.instance.client
                    .from('business_profiles')
                    .select('id')
                    .eq('id', userId)
                    .maybeSingle();

                if (businessProfileCheck != null && businessProfileCheck.isNotEmpty) {
                  determinedProfileType = 'business';
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User profile not found after login.')),
                    );
                    await Supabase.instance.client.auth.signOut();
                  }
                  setState(() { _isLoading = false; });
                  return;
                }
              }
            }

            if (determinedProfileType == 'user') {

            } else if (determinedProfileType == 'business') {

            }

            NotificationService().testNotificationCreation();
            
            if (mounted) {
  final shouldShow = await _shouldShowSlides();

            if (shouldShow) {
              await _setIntroShownDate(); // set the intro date right away
              setState(() {
                _userType = determinedProfileType;
                _showSlides = true;
                _isLoading = false;
              });
              _startSlideTimer();
            } else {
              _navigateToHome();
            }
          }
          }
        } else {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: ${error.toString()}')),
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
                    // height: 57, // Removed fixed height
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
                                  AnimatedEyeWidget(
                                    isObscured: _obscurePassword,
                                    onToggle: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    size: 18.0,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A35E3),
                      minimumSize: const Size(250, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('LOGIN', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
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
                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
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
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A35E3),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    _userType == 'business' ? 'START MANAGING' : 'GET STARTED',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, decoration: TextDecoration.none),
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
}