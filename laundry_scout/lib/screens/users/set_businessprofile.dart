import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';
import 'package:laundry_scout/screens/home/Owner/owner_home_screen.dart';
// Add this import at the top with other imports
import 'package:laundry_scout/screens/home/User/business_detail_screen.dart';
import '../../services/image_service.dart';
import '../../services/form_persistence_service.dart';

class SetBusinessProfileScreen extends StatefulWidget {
  final String username;
  final String businessName; // Add businessName parameter
  final String exactLocation; // Add exactLocation parameter

  const SetBusinessProfileScreen({
    Key? key,
    required this.username,
    required this.businessName, // Require businessName
    required this.exactLocation, // Require exactLocation
  }) : super(key: key);

  @override
  _SetBusinessProfileScreenState createState() => _SetBusinessProfileScreenState();
}

class _SetBusinessProfileScreenState extends State<SetBusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _aboutBusinessController = TextEditingController();
  final _exactLocationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _openHoursController = TextEditingController();
  bool _doesDelivery = false;
  PlatformFile? _coverPhotoFile;
  String? _coverPhotoUrl; // This variable will now be used
  bool _isLoading = false;
  // Add this line to define the missing variable
  List<String> _availableServices = ['Wash & Fold', 'Ironing', 'Deliver', 'Dry Cleaning', 'Pressing'];
  List<String> _selectedServices = [];
  Map<String, double> _servicePrices = {};
  Map<String, TextEditingController> _priceControllers = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with values passed from the previous screen
    _businessNameController.text = widget.businessName;
    _exactLocationController.text = widget.exactLocation;
    // Initialize price controllers
    _initializePriceControllers();
    // Fetch existing user data
    _fetchUserData();
    
    // Load saved form data
    _loadSavedFormData();
    
    // Load saved image
    _loadSavedImage();
    
    // Add listeners to save data when user types
    _businessNameController.addListener(_saveFormData);
    _aboutBusinessController.addListener(_saveFormData);
    _exactLocationController.addListener(_saveFormData);
    _phoneNumberController.addListener(_saveFormData);
    _emailController.addListener(_saveFormData);
    _openHoursController.addListener(_saveFormData);
  }

  void _initializePriceControllers() {
    for (String service in _availableServices) {
      _priceControllers[service] = TextEditingController(
        text: '' // Empty the price list field
      );
      // Add listener to save data when price changes
      _priceControllers[service]!.addListener(() {
        _servicePrices[service] = double.tryParse(_priceControllers[service]!.text) ?? 0.0;
        _saveFormData();
      });
    }
  }

  void _ensureControllerExists(String service) {
    if (!_priceControllers.containsKey(service)) {
      _priceControllers[service] = TextEditingController(
        text: '' // Empty the price list field
      );
      // Add listener to save data when price changes
      _priceControllers[service]!.addListener(() {
        _servicePrices[service] = double.tryParse(_priceControllers[service]!.text) ?? 0.0;
        _saveFormData();
      });
    }
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Fetch user profile data
        final response = await Supabase.instance.client
            .from('profiles')
            .select('phone_number, email')
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            _phoneNumberController.text = response['phone_number'] ?? '';
            _emailController.text = response['email'] ?? user.email ?? '';
          });
        }
      } catch (e) {
        // If no profile data exists, use user email from auth
        if (mounted && user.email != null) {
          setState(() {
            _emailController.text = user.email!;
          });
        }
      }
    }
  }

  // Load saved form data
  Future<void> _loadSavedFormData() async {
    final savedData = await FormPersistenceService.loadBusinessProfileData();
    if (savedData != null && mounted) {
      setState(() {
        _businessNameController.text = savedData['businessName'] ?? widget.businessName;
        _aboutBusinessController.text = savedData['aboutBusiness'] ?? '';
        _exactLocationController.text = savedData['exactLocation'] ?? widget.exactLocation;
        _phoneNumberController.text = savedData['phoneNumber'] ?? '';
        _emailController.text = savedData['email'] ?? '';
        _openHoursController.text = savedData['openHours'] ?? '';
        _doesDelivery = savedData['doesDelivery'] ?? false;
        
        // Load selected services
        if (savedData['selectedServices'] != null) {
          _selectedServices = List<String>.from(savedData['selectedServices']);
        }
        
        // Load service prices - keep fields empty
        if (savedData['servicePrices'] != null) {
          final Map<String, dynamic> prices = savedData['servicePrices'];
          prices.forEach((service, price) {
            _servicePrices[service] = double.tryParse(price.toString()) ?? 0.0;
            // Ensure controller exists for this service
            _ensureControllerExists(service);
            _priceControllers[service]!.text = ''; // Keep price fields empty
          });
        }
        
        // Ensure controllers exist for all selected services
        for (String service in _selectedServices) {
          _ensureControllerExists(service);
        }
      });
    }
  }

  // Load saved image
  Future<void> _loadSavedImage() async {
    final savedImage = await FormPersistenceService.loadBusinessProfileImage();
    if (savedImage != null && mounted) {
      setState(() {
        _coverPhotoFile = savedImage;
      });
    }
  }

  // Save form data
  Future<void> _saveFormData() async {
    final formData = {
      'businessName': _businessNameController.text,
      'aboutBusiness': _aboutBusinessController.text,
      'exactLocation': _exactLocationController.text,
      'phoneNumber': _phoneNumberController.text,
      'email': _emailController.text,
      'openHours': _openHoursController.text,
      'selectedServices': _selectedServices.toList(),
      'servicePrices': _servicePrices,
      'doesDelivery': _doesDelivery,
    };
    await FormPersistenceService.saveBusinessProfileData(formData);
    
    // Save image if available
    if (_coverPhotoFile != null) {
      await FormPersistenceService.saveBusinessProfileImage(_coverPhotoFile);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _aboutBusinessController.dispose();
    _exactLocationController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _openHoursController.dispose();
    // Dispose price controllers
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _coverPhotoFile = result.files.first;
        _coverPhotoUrl = null; // Clear URL when a new file is picked
      });
      // Save the image immediately
      await FormPersistenceService.saveBusinessProfileImage(_coverPhotoFile);
    } else if (result != null && result.files.first.path != null) {
       setState(() {
        _coverPhotoFile = result.files.first;
        _coverPhotoUrl = null; // Clear URL when a new file is picked
      });
      // Save the image immediately
      await FormPersistenceService.saveBusinessProfileImage(_coverPhotoFile);
    } else {
      // User canceled the picker or file bytes are null on web
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected or file format not supported.')),
      );
    }
  }

  Future<String?> _uploadCoverPhoto(String userId) async {
    if (_coverPhotoFile == null) return null;

    final String fileExtension = _coverPhotoFile!.extension ?? 'bin';
    final String fileName = 'cover_photo_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String path = 'public/$fileName'; // Supabase storage path convention

    try {
      late List<int> imageBytes;
      
      if (kIsWeb) {
        if (_coverPhotoFile!.bytes == null) {
           throw Exception('File bytes are null for cover photo on web.');
        }
        imageBytes = _coverPhotoFile!.bytes!;
      } else {
        if (_coverPhotoFile!.path == null) {
           throw Exception('File path is null for cover photo on mobile.');
        }
        imageBytes = await File(_coverPhotoFile!.path!).readAsBytes();
      }
      
      // Compress the image using ImageService
      final compressedBytes = await ImageService.compressImage(
        Uint8List.fromList(imageBytes),
      );
      
      // Upload compressed image
      await Supabase.instance.client.storage.from('businessdocuments').uploadBinary(
            path, // Use the path with 'public/' prefix
            compressedBytes,
            fileOptions: FileOptions(
              contentType: lookupMimeType(_coverPhotoFile!.name) ?? 'application/octet-stream',
            ),
          );

      // Get the public URL after successful upload
      final String publicUrl = Supabase.instance.client.storage.from('businessdocuments').getPublicUrl(path);

      if (mounted) {
         setState(() {
            _coverPhotoUrl = publicUrl; // Store the public URL in the state variable
         });
      }

      return publicUrl; // Return the public URL
    } on StorageException catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Storage Error uploading cover photo: ${e.message}')),
          );
       }
       return null;
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error uploading cover photo: ${e.toString()}')),
          );
       }
       return null;
    }
  }


  void _previewProfile() {
    // Create mock business data for preview
    Map<String, dynamic> mockBusinessData = {
      'id': 'preview-id',
      'business_name': _businessNameController.text,
      'exact_location': _exactLocationController.text,
      'about_business': _aboutBusinessController.text,
      'cover_photo_url': _coverPhotoUrl, // Use the actual cover photo URL if available
      'profile_image_url': null,
      'availability_status': 'Open Slots',
      'phone_number': _phoneNumberController.text,
      'email': _emailController.text,
      'open_hours': _openHoursController.text,
      'does_delivery': _doesDelivery,
      'selected_services': _selectedServices,
      'service_prices': _servicePrices,
      // Add cover photo file for preview if URL is not available
      '_coverPhotoFile': _coverPhotoFile,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailScreen(
          businessData: mockBusinessData,
        ),
      ),
    );
  }

  Future<void> _showCompletionDialogAndNavigate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF6F5ADC), size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Complete',
                    style: TextStyle(
                      color: Color(0xFF6F5ADC),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    if (mounted) {
      // Clear saved form data on successful submission
      await FormPersistenceService.clearBusinessProfileData();
      
      Navigator.of(context).pop(); // Close the dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
      );
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      // Upload cover photo if a new file was selected
      if (_coverPhotoFile != null && _coverPhotoUrl == null) {
         await _uploadCoverPhoto(user.id); // This will update _coverPhotoUrl state
         if (_coverPhotoUrl == null) {
            setState(() { _isLoading = false; });
            return; // Stop if upload failed
         }
      }

      try {
        await Supabase.instance.client
            .from('business_profiles')
            .upsert({
              'id': user.id,
              'business_name': _businessNameController.text.trim(),
              'about_business': _aboutBusinessController.text.trim(),
              'exact_location': _exactLocationController.text.trim(),
              // 'phone_number': _phoneNumberController.text.trim().isEmpty ? '09204343284' : _phoneNumberController.text.trim(), // Commented out until column is added to database
              'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
              // 'open_hours': _openHoursController.text.trim().isEmpty ? 'Monday - Saturday: 9am - 9pm\nSunday: 7am - 10pm' : _openHoursController.text.trim(), // Commented out until column is added to database
              'does_delivery': _doesDelivery,
              'cover_photo_url': _coverPhotoUrl,
              'services_offered': _selectedServices, // Changed from 'services' to 'services_offered'
              // 'service_prices': _servicePrices, // Commented out until column is added to database
            });

        // Show success dialog and navigate
        if (mounted) {
          await _showCompletionDialogAndNavigate();
        }
      } on PostgrestException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database Error: ${error.message}')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('General Error: ${error.toString()}')),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Added Business Profile text above cover photo
                      Center(
                        child: Text(
                          'Business Profile',
                          style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20), // Add spacing

                      // Cover Photo Upload
                      GestureDetector(
                        onTap: _pickCoverPhoto,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                            image: _coverPhotoFile != null // Use _coverPhotoFile for immediate preview
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? MemoryImage(_coverPhotoFile!.bytes!) as ImageProvider<Object>
                                        : FileImage(File(_coverPhotoFile!.path!)) as ImageProvider<Object>,
                                    fit: BoxFit.cover,
                                  )
                                : (_coverPhotoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_coverPhotoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: (_coverPhotoFile == null && _coverPhotoUrl == null) // Show upload icon only if no image is selected or loaded
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload, size: 50, color: Colors.grey[700]),
                                    const SizedBox(height: 8),
                                    Text('Click here to upload', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                                  ],
                                )
                              : null, // Show nothing if image is picked or loaded
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Business Name
                      TextFormField(
                      
                        controller: _businessNameController,
                        style: const TextStyle(color: Colors.black), // Set input text color to black
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(color: Colors.black54), // Set label text color
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Services Offered
                      Text('Services Offered', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._availableServices.map((service) {
                              final isSelected = _selectedServices.contains(service);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedServices.add(service);
                                            _servicePrices[service] = 0.0;
                                            // Ensure controller exists
                                            _ensureControllerExists(service);
                                          } else {
                                            _selectedServices.remove(service);
                                            _servicePrices.remove(service);
                                          }
                                        });
                                      },
                                      activeColor: const Color(0xFF6F5ADC),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        service,
                                        style: textTheme.bodyMedium?.copyWith(color: Colors.black),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Price',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                          controller: _priceControllers[service],
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            hintText: '',
                                            hintStyle: const TextStyle(color: Colors.black54),
                                            prefixText: '₱ ',
                                            prefixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4.0),
                                              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4.0),
                                              borderSide: const BorderSide(color: Color(0xFF6F5ADC), width: 2.0),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            _servicePrices[service] = double.tryParse(value) ?? 0.0;
                                          },
                                        ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                       ),
                       const SizedBox(height: 20),

                      // Delivery Options
                      Text('Delivery Options', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                         decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(8.0),
                         ),
                         child: Row(
                            children: [
                               Checkbox(
                                  value: _doesDelivery,
                                  onChanged: (bool? newValue) {
                                     setState(() {
                                        _doesDelivery = newValue ?? false;
                                     });
                                  },
                                  activeColor: const Color(0xFF6F5ADC), // Purple color
                               ),
                               Expanded( // Wrap Text in Expanded to prevent overflow
                                 child: Text('Does Your Business Do Delivery?', style: textTheme.bodyMedium?.copyWith(color: Colors.black)), // Set text color to black
                               ),
                            ],
                         ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By Checking this you will have an interface to manage your delivery needs for your costumers convenience such as tracking there order getting the information on where to drop off and pick up there order and they can select the services you offer to them.',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 20),

                      // About Your Business
                      Text('About Your Business', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _aboutBusinessController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.black), // Set input text color to black
                        decoration: InputDecoration(
                          hintText: 'Something about your business, Open Hours, and Contact Details.',
                          hintStyle: const TextStyle(color: Colors.black54), // Set hint text color
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please tell us about your business';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Contact Details
                      Text('Contact Details', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneNumberController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Phone Number (e.g., 09204343284)',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: Icon(Icons.phone, color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Email (optional)',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: Icon(Icons.email, color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Open Hours
                      Text('Open Hours', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _openHoursController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Monday - Saturday: 9am - 9pm\nSunday: 7am - 10pm',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: Icon(Icons.access_time, color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Exact Location
                      Text('Exact Location', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _exactLocationController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: Icon(Icons.location_on, color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Preview Button
                      OutlinedButton(
                        onPressed: _previewProfile,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Preview Profile',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Published Button
                      ElevatedButton(
                        onPressed: _saveBusinessProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F5ADC),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Text(
                          'Published',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),


                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}