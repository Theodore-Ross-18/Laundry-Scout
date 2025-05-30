import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker
import 'dart:io'; // For File
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'dart:typed_data'; // Import Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPromoScreen extends StatefulWidget {
  const AddPromoScreen({super.key});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  File? _selectedImageFile; // To store the selected image file for non-web
  Uint8List? _selectedImageBytes; // To store the selected image bytes for web

  Future<void> _pickImage() async {
    // Use FilePicker to pick files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Specify that we only want image files
      allowMultiple: false, // Only allow picking a single file
    );

    if (result != null && result.files.single.path != null) {
      if (kIsWeb) {
        // For web, get the bytes
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          _selectedImageFile = null; // Clear file reference for web
        });
      } else {
        // For mobile/desktop, get the file path
        setState(() {
          _selectedImageFile = File(result.files.single.path!);
          _selectedImageBytes = null; // Clear bytes reference for non-web
        });
      }
    } else {
      // User canceled the picker or failed to pick
      print('User canceled the picker or no file selected');
    }
  }

  void _publishPromo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
  
      String? imageUrlToStore; // To store the public URL

      if (kIsWeb && _selectedImageBytes != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Upload the binary data
        await Supabase.instance.client.storage
            .from('promoimages')
            .uploadBinary(
              fileName,
              _selectedImageBytes!,
            );
        // Get the public URL after successful upload
        imageUrlToStore = Supabase.instance.client.storage
            .from('promoimages')
            .getPublicUrl(fileName);
      } 

     
        
  
      // Save promo data
      await Supabase.instance.client.from('promos').insert({
        'creator_id': user.id, 
        'business_id': user.id, 
        'image_url': imageUrlToStore, // Store the public URL
        'created_at': DateTime.now().toIso8601String(),
      });
  
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing promo: $e')),
        );
      }
    }
  }

  // Add text fields to the build method:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Background color
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8), // AppBar background color
        elevation: 0, // No shadow
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF7B61FF), fontSize: 16), // Purple color
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement Preview functionality
              print('Preview button tapped');
            },
            child: const Text(
              'Preview',
              style: TextStyle(color: Color(0xFF7B61FF), fontSize: 16), // Purple color
            ),
          ),
        ],
        title: const Text(
          'Promote your Business',
          style: TextStyle(
            color: Color(0xFF7B61FF), // Purple color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180, // Adjust height as needed
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: (_selectedImageFile != null || _selectedImageBytes != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && _selectedImageBytes != null
                            ? Image.memory( // Use Image.memory for web
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : _selectedImageFile != null
                                ? Image.file( // Use Image.file for other platforms
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(), // Fallback empty container
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'Click here to upload',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Instructions
            const Text(
              'Instruction to achieve a good Promo Add',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Make the photo eye-catching to users.\n'
              '• Use a 16:9 aspect ratio for the uploaded promo photo.\n'
              '• Showcase your main services (e.g., same-day cleaning, delivery) clearly.\n'
              '• Ensure the photo is well-lit, clean, and professional.\n'
              '• If adding text, keep it simple and highlight key points (e.g., "Same-Day Service" or "Pick-up Available").\n'
              '• Avoid cluttered or distracting backgrounds to keep the focus on your business.',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Example
            const Text(
              'Example:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Example Image Placeholder (replace with actual image asset if available)
            Container(
              height: 157, // Adjust height as needed
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple, // Example background color
                borderRadius: BorderRadius.circular(12),
                // You can add a background image here if you have the example image asset
                image: const DecorationImage(
                   image: AssetImage('lib/assets/promo_example.png'), // Corrected asset path
                   fit: BoxFit.cover,
                ),
              ),
              // You can add the text overlay here if needed
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Published Button
            Center(
              child: ElevatedButton(
                onPressed: _publishPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF), // Purple color
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Published',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
