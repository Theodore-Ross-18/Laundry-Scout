import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_user.dart';
// Consider importing a package for social icons like font_awesome_flutter
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Helper function for creating a fade transition
Route _createFadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300), // Adjust duration as needed
  );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Add listeners to controllers to update UI for suffixIcon visibility
    _usernameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _emailController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _passwordController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _confirmPasswordController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if username already exists in the profiles table
        final existingUsername = await Supabase.instance.client
            .from('user_profiles') // Changed from 'profiles' to 'user_profiles'
            .select('username')
            .eq('username', _usernameController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingUsername != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username already taken')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; // Stop the signup process if username exists
        }

        // Check if email already exists in user_profiles table
        final existingUserEmail = await Supabase.instance.client
            .from('user_profiles')
            .select('email')
            .eq('email', _emailController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingUserEmail != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email already registered. Please use a different email or try logging in.')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; // Stop the signup process if email exists
        }

        // Check if email already exists in business_profiles table
        final existingBusinessEmail = await Supabase.instance.client
            .from('business_profiles')
            .select('email')
            .eq('email', _emailController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingBusinessEmail != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email already registered as a business account. Please use a different email or try logging in.')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; // Stop the signup process if email exists
        }

        // Proceed with Supabase auth signup (handles email uniqueness)
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailRedirectTo: 'com.yourapp.laundryscout://email-confirm', // Add your app's deep link
          data: {
            'username': _usernameController.text.trim(),
            'email_confirm': true,
          },
        );

        if (response.user != null) {
          // Check if email confirmation is required
          if (response.session == null) {
            // Email confirmation required
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please check your email and click the confirmation link to complete signup.'),
                  duration: Duration(seconds: 5),
                ),
              );
              // Optionally navigate to a "check your email" screen instead of SelectUserScreen
              // For now, we'll still navigate but show the message
              Navigator.pushReplacement(
                context,
                _createFadeRoute(SelectUserScreen(username: _usernameController.text.trim())),
              );
            }
          } else {
            // User is immediately signed in (email confirmation disabled)
            if (mounted) {
              Navigator.pushReplacement(
                context,
                _createFadeRoute(SelectUserScreen(username: _usernameController.text.trim())),
              );
            }
          }
        } else {
           // Handle cases where auth.signUp succeeds but response.user is null (less common)
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signup failed: User not created')),
              );
           }
        }
      } on AuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth Error: ${error.message}')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('General Error: $error')),
        );
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity: _fadeAnimation,
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
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Username Field
                    Center( 
                      child: SizedBox(
                        width: 298,
                        height: 57,
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
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
                            suffixIcon: _usernameController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18.0),
                                    onPressed: () {
                                      _usernameController.clear();
                                    },
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            // You can add more username validation if needed
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email Field
                    Center( 
                      child: SizedBox(
                        width: 298,
                        height: 57,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
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
                                      _emailController.clear();
                                    },
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password Field
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
                                        icon: const Icon(Icons.clear, size: 18.0),
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Confirm Password Field
                    Center( 
                      child: SizedBox(
                        width: 298,
                        height: 57,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
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
                            suffixIcon: _confirmPasswordController.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 18.0),
                                        onPressed: () {
                                          setState(() {
                                            _confirmPasswordController.clear();
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          size: 18.0,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF543CDC),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(298, 57), // Ensure button has a good size
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
                          : const Text('Sign Up'),
                    ),
                    // Social Login Buttons (Optional)
                    const SizedBox(height: 20),
                    Text('Or sign up with', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(
                          child: Image.asset('lib/assets/fb.png', height: 24, width: 24), // Use your Facebook icon asset
                          onPressed: () {
                            // TODO: Implement Facebook Sign-Up
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildSocialIcon(
                          child: Image.asset('lib/assets/google.png', height: 24, width: 24), // Use your Google icon asset
                          onPressed: () {
                            // TODO: Implement Google Sign-Up
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Added SizedBox for spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            // Navigate to Login Screen
                            Navigator.pop(context); // Assuming SignupScreen was pushed on top of LoginScreen
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for social icons (can be extracted to a common file later)
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