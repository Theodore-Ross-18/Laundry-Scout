import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';
import 'package:laundry_scout/screens/home/Owner/owner_home_screen.dart';
// Add this import at the top with other imports
import 'package:laundry_scout/screens/users/businessprofilepreview.dart';
import '../../services/image_service.dart';

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
  bool _doesDelivery = false;
  PlatformFile? _coverPhotoFile;
  String? _coverPhotoUrl; // This variable will now be used
  bool _isLoading = false;
  // Add this line to define the missing variable
  List<String> _selectedServices = ['Wash & Fold', 'Ironing', 'Deliver'];
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with values passed from the previous screen
    _businessNameController.text = widget.businessName;
    _exactLocationController.text = widget.exactLocation;
    // You might want to fetch existing profile data here if the user
    // is returning to this screen later, but for the initial flow
    // from SetBusinessInfo, initializing with passed data is correct.
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _aboutBusinessController.dispose();
    _exactLocationController.dispose();
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
    } else if (result != null && result.files.first.path != null) {
       setState(() {
        _coverPhotoFile = result.files.first;
        _coverPhotoUrl = null; // Clear URL when a new file is picked
      });
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
              'does_delivery': _doesDelivery,
              'cover_photo_url': _coverPhotoUrl,
              'services_offered': _selectedServices, // Changed from 'services' to 'services_offered'
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
                            // Placeholder for service icons - you'll need to implement this
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Example Service Icon Placeholder
                                Column(
                                  children: [
                                    Icon(Icons.iron, size: 40, color: const Color(0xFF6F5ADC)), // Updated color
                                    Text('Ironing', style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6F5ADC))), // Updated color
                                  ],
                                ),
                                Column(
                                  children: [
                                    Icon(Icons.delivery_dining, size: 40, color: const Color(0xFF6F5ADC)), // Updated color
                                    Text('Deliver', style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6F5ADC))), // Updated color
                                  ],
                                ),
                                Column(
                                  children: [
                                    Icon(Icons.local_laundry_service, size: 40, color: const Color(0xFF6F5ADC)), // Updated color
                                    Text('Wash & Fold', style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6F5ADC))), // Updated color
                                  ],
                                ),
                                // Add button placeholder
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(Icons.add, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Price and Description can be edited later', style: textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
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
                        style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8)),
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

                      const SizedBox(height: 16),

                      // Preview Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessProfilePreview(
                                businessName: _businessNameController.text,
                                location: _exactLocationController.text,
                                aboutBusiness: _aboutBusinessController.text,
                                coverPhotoUrl: _coverPhotoUrl,
                                coverPhotoFile: _coverPhotoFile, // Ensure this is passed
                                doesDelivery: _doesDelivery,
                                services: _selectedServices,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Preview Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
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