import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_user.dart';
import 'dart:async'; // Import the dart:async library

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

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // OTP Timer variables
  late Timer _timer;
  int _countdown = 60; // 60 seconds for OTP to expire

  @override
  void initState() {
    super.initState();
    print('VerificationScreen: Initializing with email: ${widget.email}');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _startTimer();

    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.isNotEmpty && i < _otpControllers.length - 1) {
          _otpFocusNodes[i + 1].requestFocus();
        }
        if (_otpControllers[i].text.isEmpty && i > 0) {
          _otpFocusNodes[i - 1].requestFocus();
        }
        setState(() {}); // To update the UI for clear button visibility
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel(); // Cancel the timer
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60; // Reset countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        // Optionally, disable OTP input fields or show a message that OTP has expired
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    final String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      if (mounted) {
        _showErrorDialog('Please enter the complete 6-digit OTP.');
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final AuthResponse response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        final user = response.user;
        if (user != null) {
          final usernameResponse = await Supabase.instance.client
              .from('user_profiles')
              .select('username')
              .eq('id', user.id)
              .maybeSingle();

          String username = ''; // Default empty username

          if (usernameResponse == null) {
            // If no profile exists, create one
            await Supabase.instance.client
                .from('user_profiles')
                .insert({'id': user.id, 'username': ''}); // Insert with empty username
            // Now, username is still empty, but a profile exists.
          } else if (usernameResponse['username'] != null) {
            username = usernameResponse['username'] as String;
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              _createFadeRoute(SelectUserScreen(username: username)),
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog('User not found after verification.');
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog('OTP verification failed. Please try again.');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showErrorDialog('Authentication Error: ${error.message}');
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });
    print('Resending OTP for email: ${widget.email}');

    if (widget.email.isEmpty) {
      if (mounted) {
        _showErrorDialog('Email address is missing. Cannot resend OTP.');
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup, // Changed from OtpType.email to OtpType.signup
        email: widget.email,
      );
      _startTimer(); // Restart the timer when OTP is resent
      if (mounted) {
        _showErrorDialog('New OTP has been sent to your email.');
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showErrorDialog('Error resending OTP: ${error.message}');
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message, style: const TextStyle(color: Colors.black)),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Please Enter OTP',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.white, // Changed to white as per request
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    'OTP expires in $_countdown seconds',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(100)),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFF543CDC), // Changed to a darker color
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 24.0), // Changed to white
                          onChanged: (value) {
                            if (value.isNotEmpty && index < _otpControllers.length - 1) {
                              _otpFocusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 298,
                    height: 57,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF543CDC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Confirm',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}