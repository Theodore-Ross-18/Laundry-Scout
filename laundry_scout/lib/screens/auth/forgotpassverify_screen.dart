import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'resetpass_screen.dart'; // Import the reset password screen

class ForgotPasswordVerifyScreen extends StatefulWidget {
  const ForgotPasswordVerifyScreen({super.key});

  @override
  _ForgotPasswordVerifyScreenState createState() => _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends State<ForgotPasswordVerifyScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _resetToken; // To store the token received after verification

  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Supabase sends the OTP to the user's email
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        // You can optionally provide a redirect URL here if needed
        // redirectTo: 'com.yourapp.laundryscout://reset-password',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Check your inbox for the OTP.')),
        );
        setState(() {
          _otpSent = true;
        });
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

  Future<void> _verifyOtp() async {
     if (_emailController.text.isEmpty || _otpController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email and OTP')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use verifyOTP with type OtpType.recovery for password reset tokens.
      // This assumes the token sent in the email body is intended for this method.
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.recovery, // Use 'recovery' type for password reset
      );

      // Check if the verification was successful and a session is returned.
      // A successful verification should establish a temporary session allowing the password update.
      if (response.session != null) {
         // Verification successful. Navigate to reset password screen.
         // The session established by verifyOTP should authorize the updateUser call
         // on the next screen. We don't strictly need to pass the token here
         // if the next screen relies on the current authenticated session.
         // However, your ResetPasswordScreen expects a token, so we'll pass the entered one.
         _resetToken = _otpController.text.trim(); // Pass the entered token

         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification successful. Proceeding to reset password.')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(resetToken: _resetToken!),
              ),
            );
         }
      } else {
         // Verification failed - session is null
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid OTP/Token or verification failed.')),
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


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFF543CDC), // Match theme
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                 Text(
                  'Reset Your Password',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Enter your email',
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
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                   style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF543CDC),
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
                      : const Text('Send Reset Email'),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter the OTP/Token from email',
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
                    ),
                    keyboardType: TextInputType.number, // Assuming OTP is numeric
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                   ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                     style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF543CDC),
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
                        : const Text('Verify OTP/Token'),
                  ),
                ],
                // The button to navigate to ResetPasswordScreen will appear
                // after successful verification within the _verifyOtp method.
              ],
            ),
          ),
        ),
      ),
    );
  }
}