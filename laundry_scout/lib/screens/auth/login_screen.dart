import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import '../home/User/home_screen.dart';
import '../home/Owner/owner_home_screen.dart'; 
// Consider importing a package for social icons like font_awesome_flutter
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'forgotpassverify_screen.dart'; // Import the new screen

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
            // TODO: Add logic here to determine if the user is a regular user or a business owner
            // based on the profile found (user_profiles or business_profiles)
            // and navigate to the appropriate home screen (HomeScreen or OwnerHomeScreen).
            // For now, it navigates to HomeScreen as before.

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

            // Navigate based on the determined profile type
            if (mounted) {
              if (profileType == 'business') {
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
                 );
              } else { // Default to user if type is 'user' or undetermined after email login
                 Navigator.pushReplacement(
                   context,
                   MaterialPageRoute(builder: (context) => const HomeScreen()),
                 );
              }
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Keep or change to Center if all children are centered
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
                      fontSize: 40, // Larger title
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center( // Center the input field
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
                                  icon: const Icon(Icons.clear, size: 18.0), // Smaller icon
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
                        onChanged: (text) => setState(() {}), // Rebuild to show/hide clear button
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center( // Center the input field
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
                              : null, // Show icons only if text is not empty
                        ),
                        obscureText: _obscurePassword, // Use state variable here
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        style: textTheme.bodyLarge,
                        onChanged: (text) => setState(() {}), // Rebuild to show/hide suffixIcon
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center( // Center the SizedBox that constrains the "Forgot Password?" alignment
                    child: SizedBox(
                      width: 298, // Match the width of the password field above
                      child: Align(
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
                          style: TextButton.styleFrom( // Add padding to make it easier to tap
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            minimumSize: Size.zero, // Allow the button to be as small as its content
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                              fontSize: 11, // Adjusted font size
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center( // Center the button
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF543CDC),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(120, 52), // Further reduced width to 120
                        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26.0), // Half of the height for a capsule shape
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
                            _createFadeRoute(const SignupScreen()), // Updated navigation to use fade route
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