import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_scout/services/notification_service.dart';
import 'owner_promo_preview.dart';
import 'package:intl/intl.dart';

class AddPromoScreen extends StatefulWidget {
  const AddPromoScreen({super.key});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final _promoTitleController = TextEditingController();
  final _promoDescriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _expirationTimeController = TextEditingController();
  final _notificationService = NotificationService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

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
    _discountController.dispose();
    _expirationDateController.dispose();
    _expirationTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
  
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      if (kIsWeb) {
      
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          _selectedImageFile = null; 
        });
      } else {
      
        setState(() {
          _selectedImageFile = File(result.files.single.path!);
          _selectedImageBytes = null;
        });
      }
    } else {
     
      print('User canceled the picker or no file selected');
    }
  }

  String? _getImageUrlForPreview() {
   
    if (kIsWeb && _selectedImageBytes != null) {
      
      return null; 
    } else if (_selectedImageFile != null) {
     
      return _selectedImageFile!.path;
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _expirationDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _expirationTimeController.text = picked.format(context);
      });
    }
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

      final now = DateTime.now();
      final List<dynamic> validPromos = [];
      for (var promo in response) {
        if (promo['expiration_date'] != null) {
          final expirationDate = DateTime.parse(promo['expiration_date']);
          if (expirationDate.isAfter(now)) {
            validPromos.add(promo);
          } else {
            // Promo has expired, delete it
            await Supabase.instance.client.from('promos').delete().eq('id', promo['id']);
          }
        } else {
          // If no expiration date, consider it valid (or handle as per business logic)
          validPromos.add(promo);
        }
      }

      setState(() {
        _existingPromos = validPromos;
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
      _discountController.text = promo['discount']?.toString() ?? '';
      if (promo['expiration_date'] != null) {
        final expirationDate = DateTime.parse(promo['expiration_date']);
        _selectedDate = expirationDate;
        _selectedTime = TimeOfDay.fromDateTime(expirationDate);
        _expirationDateController.text = DateFormat.yMd().format(expirationDate);
        _expirationTimeController.text = _selectedTime?.format(context) ?? '';
      } else {
        _selectedDate = null;
        _selectedTime = null;
        _expirationDateController.clear();
        _expirationTimeController.clear();
      }
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingPromoId = null;
      _isEditing = false;
      _promoTitleController.clear();
      _promoDescriptionController.clear();
      _discountController.clear();
      _expirationDateController.clear();
      _expirationTimeController.clear();
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  Future<void> _deletePromo(String promoId) async {
    try {
      
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
        _fetchExistingPromos(); 
        
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

      if (_discountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a discount percentage')),
        );
        return;
      }

      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiration date and time')),
        );
        return;
      }

      final int? discount = int.tryParse(_discountController.text.trim());
      if (discount == null || discount < 0 || discount > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid discount percentage between 0 and 100')),
        );
        return;
      }
  
      String? imageUrlToStore;

      if (kIsWeb && _selectedImageBytes != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await Supabase.instance.client.storage
            .from('promoimages')
            .uploadBinary(
              fileName,
              _selectedImageBytes!,
            );
        
        imageUrlToStore = Supabase.instance.client.storage
            .from('promoimages')
            .getPublicUrl(fileName);
      } else if (_selectedImageFile != null) {
        
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
        
        final updateData = {
          'promo_title': _promoTitleController.text.trim(),
          'promo_description': _promoDescriptionController.text.trim(),
          'discount': int.parse(_discountController.text.trim()),
          'expiration_date': DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ).toIso8601String(),
        };
        
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
        
        final promoData = {
          'creator_id': user.id, 
          'business_id': user.id, 
          'promo_title': _promoTitleController.text.trim(),
          'promo_description': _promoDescriptionController.text.trim(),
          'discount': int.parse(_discountController.text.trim()),
          'image_url': imageUrlToStore, 
          'expiration_date': DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ).toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };
        
        await Supabase.instance.client.from('promos').insert(promoData);
        
       
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
      
      _fetchExistingPromos();
      
     
      if (!_isEditing) {
        _promoTitleController.clear();
        _promoDescriptionController.clear();
        _discountController.clear();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8), 
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
               
                final previewData = {
                  'promo_title': _promoTitleController.text.trim(),
                  'promo_description': _promoDescriptionController.text.trim(),
                  'discount': int.tryParse(_discountController.text.trim()) ?? 0,
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
                style: TextStyle(color: Color(0xFF7B61FF), fontSize: 16), 
              ),
            ),
        ],
        title: Text(
          _isEditing ? 'Edit Promo' : 'Promote your Business',
          style: const TextStyle(
            color: Color(0xFF7B61FF), 
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
        
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180, 
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
            const SizedBox(height: 16),
            TextField(
              controller: _discountController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Discount Percentage',
                labelStyle: const TextStyle(color: Colors.black),
                hintText: 'Enter discount percentage (e.g., "20%")',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              maxLength: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expirationDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Expiration Date',
                labelStyle: const TextStyle(color: Colors.black),
                hintText: 'Select expiration date',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expirationTimeController,
              readOnly: true,
              onTap: () => _selectTime(context),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Expiration Time',
                labelStyle: const TextStyle(color: Colors.black),
                hintText: 'Select expiration time',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
           
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
         
            const Text(
              'Example:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
           
            Container(
              height: 200, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF5A35E3), 
                borderRadius: BorderRadius.circular(12),
               
                image: const DecorationImage(
                   image: AssetImage('lib/assets/promo_example.png'),
                   fit: BoxFit.cover,
                ),
              ),
              
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Center(
              child: ElevatedButton(
                onPressed: _publishPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A35E3), 
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
        
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 24),
            
            const Text(
              'Your Existing Promos',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
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
                                color: isCurrentlyEditing ? const Color(0xFF5A35E3) : Colors.grey,
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
