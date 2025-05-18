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

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin { // Added SingleTickerProviderStateMixin
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController; // Added AnimationController
  late Animation<double> _fadeAnimation; // Added Animation

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Adjust duration as needed
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the controller
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

        // Proceed with Supabase auth signup (handles email uniqueness)
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          // data: {'username': _usernameController.text}, // Remove this line
        );

        if (response.user != null) {
          // Insert the username into the profiles table
          final user = response.user!;
          try {
            await Supabase.instance.client
                .from('user_profiles')
                .insert({
                  'id': user.id,
                  'username': _usernameController.text.trim(),
                  // Remove the email line as it's not in your user_profiles schema
                  // 'email': _emailController.text.trim(),
                });

            if (mounted) {
              // Navigate to SelectUserScreen after successful signup and profile insertion
              Navigator.pushReplacement(
                context,
                _createFadeRoute(const SelectUserScreen()),
              );
            }
          } catch (dbError) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create user profile: $dbError')),
                );
             }
             // Optionally, you might want to delete the auth user if profile creation fails
             // await Supabase.instance.client.auth.admin.deleteUser(user.id);
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
                    child: FadeTransition( // Added FadeTransition here
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
                          Center( // Wrap SizedBox with Center
                            child: SizedBox(
                              width: 298,
                              height: 57,
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  // Removed contentPadding
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
                          Center( // Wrap SizedBox with Center
                            child: SizedBox(
                              width: 298,
                              height: 57,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  // Removed contentPadding
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
                          Center( // Wrap SizedBox with Center
                            child: SizedBox(
                              width: 298,
                              height: 57,
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  // Removed contentPadding
                                ),
                                obscureText: true,
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
                          Center( // Wrap SizedBox with Center
                            child: SizedBox(
                              width: 298,
                              height: 57,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                    borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                                  ),
                                  // Removed contentPadding
                                ),
                                obscureText: true,
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
                          const SizedBox(height: 20),
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
                          // Social Login Buttons (Optional)
                          // const SizedBox(height: 20),
                          // Text('Or sign up with', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                          // const SizedBox(height: 10),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     // Example: IconButton(icon: FaIcon(FontAwesomeIcons.google, color: Colors.white), onPressed: () {}),
                          //     // Example: IconButton(icon: FaIcon(FontAwesomeIcons.facebook, color: Colors.white), onPressed: () {}),
                          //   ],
                          // ),
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
  // Widget _buildSocialIcon({required Widget child, required VoidCallback onPressed}) {
  //   return InkWell(
  //     onTap: onPressed,
  //     borderRadius: BorderRadius.circular(25),
  //     child: Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         shape: BoxShape.circle,
  //          boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.1),
  //             spreadRadius: 1,
  //             blurRadius: 3,
  //           )
  //         ]
  //       ),
  //       child: child,
  //     ),
  //   );
  // }
}