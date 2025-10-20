import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_user.dart';
import 'dart:async'; 


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

class VerificationScreen extends StatefulWidget {
  final String email;
  final String username;

  const VerificationScreen({super.key, required this.email, required this.username});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

 
  late Timer _timer;
  int _countdown = 60;

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
        setState(() {}); 
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
  setState(() {
    _countdown = 60;
  });

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_countdown > 0) {
      setState(() {
        _countdown--;
      });
    } else {
      _timer.cancel();
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

          String username = widget.username; 

          if (usernameResponse == null) {

            await Supabase.instance.client
                .from('user_profiles')
                .insert({'id': user.id, 'username': username});
          } else if (usernameResponse['username'] == null || (usernameResponse['username'] as String).isEmpty) {
           
            await Supabase.instance.client
                .from('user_profiles')
                .update({'username': username})
                .eq('id', user.id);
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
  if (_countdown > 0 || _isLoading) return; // Prevent multiple taps

  setState(() {
    _isLoading = true;
  });

  try {
    await Supabase.instance.client.auth.signInWithOtp(
      email: widget.email,
      emailRedirectTo: null, // Optional: Add redirect URI if using deep links
    );

    _startTimer(); // Restart countdown

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } on AuthException catch (error) {
    if (mounted) {
      _showErrorDialog('Error resending OTP: ${error.message}');
    }
  } catch (error) {
    if (mounted) {
      _showErrorDialog('Unexpected error: $error');
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
                      color: Colors.white, 
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0), // smaller spacing
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.1, // adaptive width (~10% of screen)
                            height: 55,
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
                                fillColor: Color(0xFF5A35E3),
                              ),
                              style: const TextStyle(color: Colors.white, fontSize: 22.0),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < _otpControllers.length - 1) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 30),
                 TextButton(
                    onPressed: (_isLoading || _countdown > 0) ? null : _resendOtp,
                    child: Text(
                      _countdown > 0 ? 'Resend in $_countdown s' : 'Resend OTP',
                      style: const TextStyle(
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
                        backgroundColor: const Color(0xFF5A35E3),
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