import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'set_businessprofile.dart';

class SetBusinessInfoScreen extends StatefulWidget {
  final String username;
  const SetBusinessInfoScreen({super.key, required this.username});

  @override
  _SetBusinessInfoScreenState createState() => _SetBusinessInfoScreenState();
}

class _SetBusinessInfoScreenState extends State<SetBusinessInfoScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showForm = false;
  Timer? _timer;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _confirmEmailController = TextEditingController();

  File? _birFile;
  File? _certificateFile;
  File? _permitFile;

  bool _isEmailVerified = false;
  bool _isVerifyingOtp = false;
  bool _isSubmitting = false;
  bool _submissionComplete = false;

  final List<Map<String, String>> slides = [
    {
      'image': 'lib/assets/user/slides/first.png',
      'title': 'Welcome, Business Owner!',
      'description': 'Let\'s get your laundry business set up on Laundry Scout.',
    },
    {
      'image': 'lib/assets/user/slides/second.png',
      'title': 'Showcase Your Services',
      'description': 'Reach new customers and manage your operations efficiently.',
    },
    {
      'image': 'lib/assets/user/slides/third.png',
      'title': 'Grow Your Business',
      'description': 'Join our network and make laundry services more accessible.',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        timer.cancel();
        if (mounted) {
           setState(() {
             _showForm = true;
           });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _confirmEmailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _timer?.cancel();
      setState(() {
        _showForm = true;
      });
    }
  }

  void _skipSlides() {
    _timer?.cancel();
    setState(() {
      _showForm = true;
    });
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and verification code')),
      );
      return;
    }
    setState(() { _isVerifyingOtp = true; });
    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email, email: email, token: otp,
      );
      if (res.user != null) {
        if (mounted) {
          setState(() { _isEmailVerified = true; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification failed. Please try again.')),
            );
         }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${error.message}')),
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
        setState(() { _isVerifyingOtp = false; });
      }
    }
  }

  Future<void> _pickFile(Function(File) onFilePicked, String fileTypeLabel) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        onFilePicked(File(result.files.single.path!));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $fileTypeLabel selected or file path is invalid.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking $fileTypeLabel: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitBusinessInfo() async {
    if (!_isEmailVerified) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email first.')),
        );
        return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    if (_confirmEmailController.text.trim() != _emailController.text.trim()) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmed email must match your registered email.')),
        );
        return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() { _isSubmitting = true; });
      String? birUrl, certificateUrl, permitUrl;
      try {
        final userId = user.id;
        if (_birFile != null) {
          final String fileExtension = _birFile!.path.split('.').last;
          final String fileName = 'bir_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          await Supabase.instance.client.storage.from('business_documents').upload(fileName, _birFile!);
          birUrl = Supabase.instance.client.storage.from('business_documents').getPublicUrl(fileName);
        }
        if (_certificateFile != null) {
          final String fileExtension = _certificateFile!.path.split('.').last;
          final String fileName = 'certificate_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          await Supabase.instance.client.storage.from('business_documents').upload(fileName, _certificateFile!);
          certificateUrl = Supabase.instance.client.storage.from('business_documents').getPublicUrl(fileName);
        }
        if (_permitFile != null) {
          final String fileExtension = _permitFile!.path.split('.').last;
          final String fileName = 'permit_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          await Supabase.instance.client.storage.from('business_documents').upload(fileName, _permitFile!);
          permitUrl = Supabase.instance.client.storage.from('business_documents').getPublicUrl(fileName);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading files: ${e.toString()}')),
          );
        }
        setState(() { _isSubmitting = false; });
        return;
      }
      try {
        await Supabase.instance.client
            .from('business_profiles')
            .upsert({
              'id': user.id,
              'username': widget.username,
              'owner_first_name': _firstNameController.text.trim(),
              'owner_last_name': _lastNameController.text.trim(),
              'business_name': _businessNameController.text.trim(),
              'business_address': _businessAddressController.text.trim(),
              'business_phone_number': _phoneNumberController.text.trim(),
              'email': _emailController.text.trim(),
              'bir_registration_url': birUrl,
              'business_certificate_url': certificateUrl,
              'mayors_permit_url': permitUrl,
            });
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _submissionComplete = true;
          });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting business info: ${error.toString()}')),
          );
          setState(() { _isSubmitting = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget bodyContent;
    if (!_showForm) {
      bodyContent = _buildSlides(textTheme);
    } else if (_isSubmitting) {
      bodyContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            SizedBox(height: 20),
            Text('Submitting...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    } else if (_submissionComplete) {
      bodyContent = _buildVerifiedScreen(textTheme);
    } else {
      bodyContent = _buildBusinessInfoForm(textTheme);
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(''),
        actions: _showForm && !_isSubmitting && !_submissionComplete
            ? null
            : (_showForm ? null : [
                TextButton(
                  onPressed: _skipSlides,
                  child: const Text('Skip', style: TextStyle(color: Colors.white)),
                ),
              ]),
      ),
      body: bodyContent,
    );
  }

  Widget _buildSlides(TextTheme textTheme) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) {
              setState(() { _currentPage = index; });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(slides[index]['image']!, height: 250),
                    const SizedBox(height: 40),
                    Text(
                      slides[index]['title']!,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slides[index]['description']!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                ),
                child: Text(
                  _currentPage == slides.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoForm(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'LET\'S GET STARTED',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildFormTextField(
                      controller: _firstNameController,
                      labelText: 'First name',
                      textTheme: textTheme,
                       validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your first name';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormTextField(
                      controller: _lastNameController,
                      labelText: 'Last name',
                      textTheme: textTheme,
                       validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your last name';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _phoneNumberController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                textTheme: textTheme,
                 validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) return 'Please enter a valid phone number';
                    return null;
                  },
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _businessNameController,
                labelText: 'Business Name',
                textTheme: textTheme,
                 validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your business name';
                    return null;
                  },
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _businessAddressController,
                labelText: 'Business Address',
                textTheme: textTheme,
                 validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your business address';
                    return null;
                  },
              ),
              const SizedBox(height: 20),
              _buildFormTextField(
                controller: _emailController,
                labelText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                textTheme: textTheme,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildFormTextField(
                controller: _confirmEmailController, // Use confirm email controller
                labelText: 'Confirm Email Address',
                keyboardType: TextInputType.emailAddress,
                textTheme: textTheme,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your email';
                  if (value != _emailController.text) return 'Emails do not match';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (!_isEmailVerified) ...[
                _buildFormTextField(
                  controller: _otpController,
                  labelText: 'Verification Code (OTP)',
                  keyboardType: TextInputType.number,
                  textTheme: textTheme,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter the OTP';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isVerifyingOtp ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: _isVerifyingOtp
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Verify Email', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 10),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text('Email Verified', style: textTheme.bodyMedium?.copyWith(color: Colors.greenAccent)),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _buildFileUploadField(
                label: 'Attach BIR Registration',
                file: _birFile,
                onTap: () => _pickFile((file) => setState(() => _birFile = file), 'BIR Registration'),
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildFileUploadField(
                label: 'Business Certificate',
                file: _certificateFile,
                onTap: () => _pickFile((file) => setState(() => _certificateFile = file), 'Business Certificate'),
                textTheme: textTheme,
              ),
              const SizedBox(height: 20),
              _buildFileUploadField(
                label: 'Business Mayors Permit',
                file: _permitFile,
                onTap: () => _pickFile((file) => setState(() => _permitFile = file), 'Mayor\'s Permit'),
                textTheme: textTheme,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBusinessInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)))
                    : const Text('Submit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // THIS IS THE DEFINITION OF _buildFormTextField
  Widget _buildFormTextField({
    required TextEditingController controller,
    required String labelText,
    required TextTheme textTheme,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.white)),
        suffixIcon: suffixIcon,
      ),
      style: textTheme.bodyMedium?.copyWith(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
    );
  }

  // THIS IS THE DEFINITION OF _buildFileUploadField
  Widget _buildFileUploadField({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200]?.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: file != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: (file.path.toLowerCase().endsWith('.jpg') ||
                             file.path.toLowerCase().endsWith('.jpeg') ||
                             file.path.toLowerCase().endsWith('.png'))
                          ? Image.file(file, fit: BoxFit.contain)
                          : Text(
                              file.path.split(Platform.isWindows ? '\\' : '/').last,
                              style: textTheme.bodySmall?.copyWith(color: Colors.black87),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.grey[700], size: 40),
                      const SizedBox(height: 8),
                      Text('Click here to upload', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // THIS IS THE DEFINITION OF _buildVerifiedScreen
  Widget _buildVerifiedScreen(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 100),
            const SizedBox(height: 24),
            Text(
              'Information Submitted!',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Your business information has been successfully submitted. You can now proceed to set up your business profile.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => SetBusinessProfileScreen(username: widget.username)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              ),
              child: const Text('Set Up Business Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

} // <-- THIS IS THE FINAL CLOSING BRACE FOR THE _SetBusinessInfoScreenState CLASS. ALL METHODS ABOVE MUST BE INSIDE.