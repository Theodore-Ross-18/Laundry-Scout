import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_user.dart';
// Consider importing a package for social icons like font_awesome_flutter
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if username already exists in the profiles table
        final existingUsername = await Supabase.instance.client
            .from('profiles')
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
          // Insert the username and email into the profiles table
          final user = response.user!;
          await Supabase.instance.client
              .from('profiles')
              .insert({
                'id': user.id,
                'username': _usernameController.text.trim(),
                'email': _emailController.text.trim(), // Add this line to insert email
              });

          if (mounted) {
            // Navigate to SelectUserScreen after successful signup and profile insertion
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SelectUserScreen()),
            );
          }
        }
      } on AuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred')),
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
            child: Form( // Show the form directly
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
                          'Sign Up',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
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
                              return 'Please enter a username';
                            }
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
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
                              return 'Please enter your email';
                            }
                            // Add more robust email validation if needed
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
                              return 'Please enter a password';
                            }
                            // Add password strength validation if needed
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
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
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
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
                              : const Text('Sign Up'),
                        ),
                        const SizedBox(height: 20),
                         Text(
                          'Or sign in With',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'I have an account ',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Go back to LoginScreen
                              },
                              child: const Text(
                                'Log In',
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