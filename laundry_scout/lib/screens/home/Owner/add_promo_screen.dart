import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker
import 'dart:io'; // For File
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'dart:typed_data'; // Import Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/services/notification_service.dart';
import 'owner_promo_preview.dart';

class AddPromoScreen extends StatefulWidget {
  const AddPromoScreen({super.key});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  File? _selectedImageFile; // To store the selected image file for non-web
  Uint8List? _selectedImageBytes; // To store the selected image bytes for web
  final _promoTitleController = TextEditingController();
  final _promoDescriptionController = TextEditingController();
  final _notificationService = NotificationService();
  
  // New state variables for existing promos
  List<dynamic> _existingPromos = [];
  bool _isLoadingPromos = false;
  String? _editingPromoId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingPromos();
  }

  @override
  void dispose() {
    _promoTitleController.dispose();
    _promoDescriptionController.dispose();
    super.dispose();
  }

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

  String? _getImageUrlForPreview() {
    // Return temporary image URL for preview
    if (kIsWeb && _selectedImageBytes != null) {
      // For web, create a data URL from bytes
      return null; // Will show placeholder in preview
    } else if (_selectedImageFile != null) {
      // For mobile, create a file path URL
      return _selectedImageFile!.path;
    }
    return null; // No image selected
  }

  Future<void> _fetchExistingPromos() async {
    setState(() {
      _isLoadingPromos = true;
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('promos')
          .select('*')
          .eq('business_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _existingPromos = response;
        _isLoadingPromos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPromos = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promos: $e')),
        );
      }
    }
  }

  void _editPromo(Map<String, dynamic> promo) {
    setState(() {
      _editingPromoId = promo['id'];
      _isEditing = true;
      _promoTitleController.text = promo['promo_title'] ?? '';
      _promoDescriptionController.text = promo['promo_description'] ?? '';
      // Clear image selections when editing
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
    
    // Scroll to top to show the form
    if (mounted) {
      // The form is at the top, so user will see it
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingPromoId = null;
      _isEditing = false;
      _promoTitleController.clear();
      _promoDescriptionController.clear();
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _deletePromo(String promoId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Promo', style: TextStyle(color: Colors.black)),
          content: const Text('Are you sure you want to delete this promo?', style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await Supabase.instance.client.from('promos').delete().eq('id', promoId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo deleted successfully!')),
        );
        _fetchExistingPromos(); // Refresh the list
        
        // If we were editing this promo, cancel the edit
        if (_editingPromoId == promoId) {
          _cancelEdit();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting promo: $e')),
        );
      }
    }
  }

  void _publishPromo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      
      // Validate inputs
      if (_promoTitleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a promo title')),
        );
        return;
      }
      
      if (_promoDescriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a promo description')),
        );
        return;
      }
  
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
      } else if (_selectedImageFile != null) {
        // Handle mobile image upload
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('promoimages')
            .upload(
              fileName,
              _selectedImageFile!,
            );
        imageUrlToStore = Supabase.instance.client.storage
            .from('promoimages')
            .getPublicUrl(fileName);
      }

      if (_isEditing && _editingPromoId != null) {
        // Update existing promo
        final updateData = {
          'promo_title': _promoTitleController.text.trim(),
          'promo_description': _promoDescriptionController.text.trim(),
        };
        
        // Only update image URL if a new image was selected
        if (imageUrlToStore != null) {
          updateData['image_url'] = imageUrlToStore;
        }
        
        await Supabase.instance.client
            .from('promos')
            .update(updateData)
            .eq('id', _editingPromoId!);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promo updated successfully!')),
          );
          _cancelEdit();
        }
      } else {
        // Create new promo
        final promoData = {
          'creator_id': user.id, 
          'business_id': user.id, 
          'promo_title': _promoTitleController.text.trim(),
          'promo_description': _promoDescriptionController.text.trim(),
          'image_url': imageUrlToStore, // Store the public URL
          'created_at': DateTime.now().toIso8601String(),
        };
        
        await Supabase.instance.client.from('promos').insert(promoData);
        
        // Send notifications to all users about the new promo
        await _notificationService.createPromoNotification(
          businessId: user.id,
          promoTitle: _promoTitleController.text.trim(),
          promoDescription: _promoDescriptionController.text.trim(),
          promoImageUrl: imageUrlToStore,
        );
    
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promo published successfully!')),
          );
        }
      }
      
      _fetchExistingPromos(); // Refresh the list
      
      // Clear form after successful operation
      if (!_isEditing) {
        _promoTitleController.clear();
        _promoDescriptionController.clear();
        _selectedImageFile = null;
        _selectedImageBytes = null;
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
        leading: const BackButton(color: Colors.black),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'Cancel Edit',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          else
            TextButton(
              onPressed: () {
                // Navigate to preview screen with current data
                final previewData = {
                  'promo_title': _promoTitleController.text.trim(),
                  'promo_description': _promoDescriptionController.text.trim(),
                  'image_url': _getImageUrlForPreview(),
                };
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerPromoPreviewScreen(
                      promoData: previewData,
                    ),
                  ),
                );
              },
              child: const Text(
                'Preview',
                style: TextStyle(color: Color(0xFF7B61FF), fontSize: 16), // Purple color
              ),
            ),
        ],
        title: Text(
          _isEditing ? 'Edit Promo' : 'Promote your Business',
          style: const TextStyle(
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
            // Promo Title Field
            TextField(
              controller: _promoTitleController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Promo Title',
                labelStyle: const TextStyle(color: Colors.black),
                hintText: 'Enter your promo title (e.g., "Summer Special!"',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            // Promo Description Field
            TextField(
              controller: _promoDescriptionController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Promo Description',
                labelStyle: const TextStyle(color: Colors.black),
                hintText: 'Describe your promo offer (e.g., "20% off on all laundry services this week!")',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              maxLength: 200,
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
            const SizedBox(height: 10),
            // Example Image Placeholder (replace with actual image asset if available)
            Container(
              height: 200, // Adjust height as needed
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
                child: Text(
                  _isEditing ? 'Update Promo' : 'Published',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            // Divider
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 24),
            
            // Existing Promos Section
            const Text(
              'Your Existing Promos',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Existing Promos List
            if (_isLoadingPromos)
              const Center(child: CircularProgressIndicator())
            else if (_existingPromos.isEmpty)
              const Text(
                'No promos found. Create your first promo above!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _existingPromos.length,
                itemBuilder: (context, index) {
                  final promo = _existingPromos[index];
                  final isCurrentlyEditing = _editingPromoId == promo['id'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrentlyEditing
                            ? Border.all(color: const Color(0xFF7B61FF), width: 2)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: promo['image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  promo['image_url'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                              ),
                        title: Text(
                          promo['promo_title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              promo['promo_description'] ?? 'No Description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Created: ${_formatDate(promo['created_at'])}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isCurrentlyEditing ? Icons.edit : Icons.edit_outlined,
                                color: isCurrentlyEditing ? const Color(0xFF7B61FF) : Colors.grey,
                              ),
                              onPressed: () => _editPromo(promo),
                              tooltip: 'Edit Promo',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deletePromo(promo['id']),
                              tooltip: 'Delete Promo',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
