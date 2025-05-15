import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

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
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            const SnackBar(content: Text('Unexpected error occurred')),
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
    // Get the text theme from the current context
    final textTheme = Theme.of(context).textTheme;
    // Get the elevated button theme for styling social login buttons
    final elevatedButtonTheme = Theme.of(context).elevatedButtonTheme;

    return Scaffold(
      // appBar: AppBar( // Removed AppBar to match the image
      //   title: const Text('Login'),
      // ),
      body: SafeArea( // Added SafeArea
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Increased padding
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch
                children: [
                  const SizedBox(height: 40), // Space from top
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textTheme.displayLarge?.color ?? Colors.white, // Use themed color
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email or Username',
                      // border: OutlineInputBorder(), // Using global theme
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or username';
                      }
                      // Basic email validation, can be enhanced
                      // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      //   return 'Please enter a valid email address';
                      // }
                      return null;
                    },
                    style: textTheme.bodyLarge, // Ensure input text color from theme
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      // border: OutlineInputBorder(), // Using global theme
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    style: textTheme.bodyLarge, // Ensure input text color from theme
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement Forgot Password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: textTheme.bodyMedium?.color ?? Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: elevatedButtonTheme.style, // Use themed button style
                    child: _isLoading
                        ? const SizedBox( // Smaller CircularProgressIndicator
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Or sign in with',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded( // Make buttons take available space
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement Google Sign-In
                          },
                          icon: const Icon(Icons.android_outlined), // Placeholder for Google icon
                          label: const Text('Google'),
                          style: elevatedButtonTheme.style?.copyWith(
                             backgroundColor: MaterialStateProperty.all(Colors.white),
                             foregroundColor: MaterialStateProperty.all(Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded( // Make buttons take available space
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement Apple Sign-In
                          },
                          icon: const Icon(Icons.apple), // Placeholder for Apple icon
                          label: const Text('Apple'),
                          style: elevatedButtonTheme.style?.copyWith(
                             backgroundColor: MaterialStateProperty.all(Colors.white),
                             foregroundColor: MaterialStateProperty.all(Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Space before sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          'Sign Up',
                           style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve({}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Space at bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}