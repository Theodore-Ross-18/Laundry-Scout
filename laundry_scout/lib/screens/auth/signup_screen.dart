import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verification_screen.dart';
import 'select_user.dart';
import 'package:laundry_scout/widgets/animated_eye_widget.dart'; 


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
        
        final existingUsername = await Supabase.instance.client
            .from('user_profiles') 
            .select('username')
            .eq('username', _usernameController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingUsername != null) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Signup Error', style: TextStyle(color: Colors.black)),
                  content: const Text('Username already taken', style: TextStyle(color: Colors.black)),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; 
        }

        
        final existingUserEmail = await Supabase.instance.client
            .from('user_profiles')
            .select('email')
            .eq('email', _emailController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingUserEmail != null) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Signup Error', style: TextStyle(color: Colors.black)),
                  content: const Text('Email already registered. Please use a different email or try logging in.', style: TextStyle(color: Colors.black)),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; 
        }

        
        final existingBusinessEmail = await Supabase.instance.client
            .from('business_profiles')
            .select('email')
            .eq('email', _emailController.text.trim())
            .limit(1)
            .maybeSingle();

        if (existingBusinessEmail != null) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Signup Error'),
                  content: const Text('Email already registered as a business account. Please use a different email or try logging in.', style: TextStyle(color: Colors.black)),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK', style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
          setState(() {
            _isLoading = false;
          });
          return; 
        }

        
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailRedirectTo: 'com.yourapp.laundryscout://email-confirm', 
          data: {
            'username': _usernameController.text.trim(),
            'email_confirm': true,
          },
        );

        if (response.user != null) {
         
          if (response.session == null) {
           
            if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Signup Successful', style: TextStyle(color: Colors.black)),
                    content: const Text('Please check your email and enter the verification code to complete signup.', style: TextStyle(color: Colors.black)),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK', style: TextStyle(color: Colors.black)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            _createFadeRoute(VerificationScreen(email: _emailController.text.trim(), username: _usernameController.text.trim())),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            
            if (mounted) {
              Navigator.pushReplacement(
                context,
                _createFadeRoute(SelectUserScreen(username: _usernameController.text.trim())),
              );
            }
          }
        } else {
           
           if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Signup Error'),
                    content: const Text('Signup failed: User not created'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
           }
        }
      } on AuthException catch (error) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Authentication Error'),
              content: Text('Auth Error: ${error.message}', style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } catch (error) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('General Error: $error', style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
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
                        // height: 57, // Removed fixed height
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
                                        icon: const Icon(Icons.clear, size: 18.0),
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
                    
                    Center( 
                      child: SizedBox(
                        width: 298,
                        // height: 57, // Removed fixed height
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
                                      AnimatedEyeWidget(
                                        isObscured: _obscureConfirmPassword,
                                        onToggle: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                    Center(
                      child: SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A35E3),
                            foregroundColor: Colors.white,
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
                              : const Text('Sign Up'),
                        ),
                      ),
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
}