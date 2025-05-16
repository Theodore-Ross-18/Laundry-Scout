import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';
// Consider importing a package for social icons like font_awesome_flutter
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'forgotpassverify_screen.dart'; // Import the new screen

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

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final identifier = _emailController.text.trim();
        final password = _passwordController.text;
        String? emailToSignIn;

        // Check if the input is likely an email
        if (identifier.contains('@')) {
          emailToSignIn = identifier;
        } else {
          // Assume it's a username, query the profiles table
          // Use maybeSingle() to handle cases where the username is not found
          final response = await Supabase.instance.client
              .from('profiles')
              .select('email')
              .eq('username', identifier)
              .maybeSingle(); // Changed from single() to maybeSingle()

          if (response != null && response.isNotEmpty) { // Check if response is not null and not empty
            emailToSignIn = response['email'] as String?;
          } else {
            // Username not found or query returned no results
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Username not found')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop the sign-in process
          }
        }

        // Proceed with sign-in using the determined email
        if (emailToSignIn != null) {
          final authResponse = await Supabase.instance.client.auth.signInWithPassword(
            email: emailToSignIn,
            password: password,
          );

          if (authResponse.user != null) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
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
      body: SafeArea(
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
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 32, // Larger title
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Username or email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or username';
                      }
                      return null;
                    },
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                       border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18.0)), // Apply border radius
                        borderSide: BorderSide(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement Forgot Password
                        // Navigate to the ForgotPasswordVerifyScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordVerifyScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        // Style directly as TextButtonTheme might be overridden by general white
                        style: TextStyle(color: Colors.white.withOpacity(0.8), decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF543CDC), // Darker purple for button
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
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
                        // child: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24), // Facebook Blue
                        child: Image.asset('lib/assets/fb.png', height: 24, width: 24), // Use your Facebook icon asset
                        onPressed: () {
                          // TODO: Implement Facebook Sign-In
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildSocialIcon(
                        // child: Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))), // Google Blue
                        child: Image.asset('lib/assets/google.png', height: 24, width: 24), // Use your Google icon asset
                        onPressed: () {
                          // TODO: Implement Google Sign-In
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildSocialIcon(
                        // child: Icon(Icons.apple, color: Colors.black, size: 24), // Apple Black
                        child: Image.asset('lib/assets/apple.png', height: 24, width: 24), // Use your Apple icon asset
                        onPressed: () {
                          // TODO: Implement Apple Sign-In
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
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
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
      ),
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