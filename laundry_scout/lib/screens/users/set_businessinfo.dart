import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:mime/mime.dart'; 
import '../../services/form_persistence_service.dart';
import '../home/Owner/owner_home_screen.dart';

class SetBusinessInfoScreen extends StatefulWidget {
  final String username;
  final String email;
  final String? ownerId;

  const SetBusinessInfoScreen({super.key, required this.username, required this.email, this.ownerId});

  @override
  _SetBusinessInfoScreenState createState() => _SetBusinessInfoScreenState();
}

class _SetBusinessInfoScreenState extends State<SetBusinessInfoScreen> {
  final PageController _pageController = PageController();
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

  final _confirmEmailController = TextEditingController();


  PlatformFile? _birFile; 
  PlatformFile? _certificateFile; 
  PlatformFile? _permitFile; 

  bool _isEmailVerified = false;
  bool _isSubmitting = false;
  bool _submissionComplete = false;


  final List<Map<String, String>> slides = [
    {
      'image': 'lib/assets/user/slides/first.png',
      'title': 'Welcome, Laundry Shop Owner!',
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
    _emailController.text = widget.email;
    _firstNameController.text = widget.username;
    if (user != null && user.email != null && _emailController.text.isEmpty) {
      _emailController.text = user.email!;
    }
  
    _isEmailVerified = true;
    

    _loadSavedFormData();
   
    _firstNameController.addListener(_saveFormData);
    _lastNameController.addListener(_saveFormData);
    _phoneNumberController.addListener(_saveFormData);
    _businessNameController.addListener(_saveFormData);
    _businessAddressController.addListener(_saveFormData);
    _confirmEmailController.addListener(_saveFormData);
    
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

  Future<void> _loadSavedFormData() async {

    final savedData = await FormPersistenceService.loadBusinessInfoData();
    if (savedData != null && mounted) {
      setState(() {
        _firstNameController.text = savedData['firstName'] ?? '';
        _lastNameController.text = savedData['lastName'] ?? '';
        _phoneNumberController.text = savedData['phoneNumber'] ?? '';
        _businessNameController.text = savedData['businessName'] ?? '';
        _businessAddressController.text = savedData['businessAddress'] ?? '';
        _confirmEmailController.text = savedData['confirmEmail'] ?? '';
        _isEmailVerified = savedData['isEmailVerified'] ?? false;
      });
    }
  }

  Future<void> _saveFormData() async {
    final formData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phoneNumber': _phoneNumberController.text,
      'businessName': _businessNameController.text,
      'businessAddress': _businessAddressController.text,
      'confirmEmail': _confirmEmailController.text,
      'isEmailVerified': _isEmailVerified,
    };
    await FormPersistenceService.saveBusinessInfoData(formData);
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

  Future<void> _pickFile(Function(PlatformFile) onFilePicked, String fileTypeLabel) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: kIsWeb, 
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;

        if (kIsWeb && pickedFile.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load file bytes for $fileTypeLabel on web.')),
            );
          }
          return;
        }
       
        if (!kIsWeb && pickedFile.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File path is invalid for $fileTypeLabel.')),
            );
          }
          return;
        }
        onFilePicked(pickedFile);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $fileTypeLabel selected.')),
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
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    
    if (_birFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your BIR Registration.')),
      );
      return;
    }
    if (_certificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your Business Certificate.')),
      );
      return;
    }
    if (_permitFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your Mayor\'s Permit.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() { _isSubmitting = true; });
      String? birUrl, certificateUrl, permitUrl;

      try {
        final userId = user.id;

        Future<String?> uploadDocument(PlatformFile? file, String docType, String businessName) async {
          if (file == null) return null; 
          final String fileExtension = file.extension ?? 'bin';
          final String fileName = '${businessName}/${docType}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

          if (kIsWeb) {
            if (file.bytes == null) {
              throw Exception('File bytes are null for $docType on web.');
            }
            await Supabase.instance.client.storage.from('businessdocuments').uploadBinary(
                  fileName,
                  file.bytes!,
                  fileOptions: FileOptions(
                    contentType: lookupMimeType(file.name) ?? 'application/octet-stream' // Corrected line
                  ),
                );
          } else {
            if (file.path == null) {
              throw Exception('File path is null for $docType on mobile.');
            }
            await Supabase.instance.client.storage.from('businessdocuments').upload(
                  fileName,
                  File(file.path!),
                );
          }
          return Supabase.instance.client.storage.from('businessdocuments').getPublicUrl(fileName);
        }

        birUrl = await uploadDocument(_birFile, 'bir', _businessNameController.text.trim());
        certificateUrl = await uploadDocument(_certificateFile, 'certificate', _businessNameController.text.trim());
        permitUrl = await uploadDocument(_permitFile, 'permit', _businessNameController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading files: ${e.toString()})')),
          );
        }
        setState(() { _isSubmitting = false; });
        return;
      }
      try {
      
        final String businessProfileId = user.id;


        await Supabase.instance.client
            .from('business_profiles')
            .upsert({
              'id': businessProfileId,
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

              'owner_id': widget.ownerId,

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
          
                LayoutBuilder(
                  builder: (context, constraints) {
                  
                    bool isMobile = MediaQuery.of(context).size.width < 600;
                    
                    if (isMobile) {
                     
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A35E3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: _skipSlides,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    } else {
                    
                      return TextButton(
                        onPressed: _skipSlides,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                  },
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
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
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
                      color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
                  foregroundColor: const Color(0xFF5A35E3),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                ),
                child: Text(
                  _currentPage == slides.length - 1 ? 'GET STARTED' : 'Next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
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
              
              const SizedBox(height: 30),
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
                    foregroundColor: const Color(0xFF5A35E3),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
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
        labelStyle: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildFileUploadField({
    required String label,
    required PlatformFile? file,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    bool isImage =
        (file?.extension?.toLowerCase() == 'jpg' ||
         file?.extension?.toLowerCase() == 'jpeg' ||
         file?.extension?.toLowerCase() == 'png');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              image: isImage && file != null
                  ? DecorationImage(
                      image: kIsWeb
                          ? MemoryImage(file.bytes!) as ImageProvider<Object>
                          : FileImage(File(file.path!)) as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: file == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(height: 8),
                        Text('Click to upload', style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  )
                : isImage
                    ? null 
                    : Center(
                        child: Text(
                          file.name,
                          style: textTheme.bodySmall?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 8),
        if (file != null && !isImage)
          Text(
            file.name,
            style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
          ),
      ],
    );
  }

  Widget _buildVerifiedScreen(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            Text(
              'Submission Complete!',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'The Admin Will Verify the Requirement, but you can setup your business profile for now.',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A35E3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              ),
              child: const Text(
                'Setup Business Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
