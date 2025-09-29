import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'dart:typed_data'; // Import for Uint8List
import 'dart:io'; // Import for File class
import '../../../widgets/optimized_image.dart';
import 'package:laundry_scout/screens/home/Owner/owner_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:laundry_scout/screens/home/User/business_detail_screen.dart'; // Import for BusinessDetailScreen
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final _aboutUsController = TextEditingController();
  final _termsAndConditionsController = TextEditingController(); // New controller for Terms and Conditions
  
  // Services Offered
  final List<String> _availableServices = [
    'Drop Off',
    'Wash & Fold',
    'Delivery',
    'Pick Up',
    'Self Service',
    'Dry Clean',
    'Ironing',
  ];
  List<String> _selectedServices = [];
  
  // Pricelist - Make it final since it's modified through methods
  final List<Map<String, dynamic>> _pricelist = [];
  // Removed _serviceNameController and _priceController as per user request.
  // final _serviceNameController = TextEditingController();
  // final _priceController = TextEditingController();
  
  // Controllers for editing existing pricelist items
  final Map<int, TextEditingController> _editServiceControllers = {};
  final Map<int, TextEditingController> _editPriceControllers = {};
  final Set<int> _editingIndices = {};
  
  // Weekly Schedule (currently not shown in UI)
  List<Map<String, dynamic>> _weeklySchedule = [];
  final Map<String, TextEditingController> _openControllers = {};
  final Map<String, TextEditingController> _closeControllers = {};
  final Map<String, bool> _closedDays = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _deliveryAvailable = false;
  Map<String, dynamic>? _businessProfile;
  Map<String, String>? _selectedSchedule;

  // Add a controller for open hours
  final _openHoursController = TextEditingController();
  final _pickupTimeController = TextEditingController();
  final _dropoffTimeController = TextEditingController();

  // New lists of controllers for dynamic time slots
  final List<TextEditingController> _pickupSlotControllers = [];
  final List<TextEditingController> _dropoffSlotControllers = [];

  // For image upload
  File? _selectedImageFile; // To store the selected image file for non-web
  Uint8List? _selectedImageBytes; // To store the selected image bytes for web
  String? _coverPhotoUrl; // To store the current cover photo URL

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _aboutUsController.dispose();
    _termsAndConditionsController.dispose();
    // Removed _serviceNameController.dispose() and _priceController.dispose() as per user request.
    // _serviceNameController.dispose();
    // _priceController.dispose();
    
    // Dispose editing controllers
    for (var controller in _editServiceControllers.values) {
      controller.dispose();
    }
    for (var controller in _editPriceControllers.values) {
      controller.dispose();
    }
    
    // Dispose schedule controllers
    for (var c in _openControllers.values) {
      c.dispose();
    }
    for (var c in _closeControllers.values) {
      c.dispose();
    }
    // removed weekly schedule controllers
    
    // Dispose the new open hours controller
    _openHoursController.dispose();
    _pickupTimeController.dispose();
    _dropoffTimeController.dispose();

    // Dispose new dynamic time slot controllers
    for (var controller in _pickupSlotControllers) {
      controller.dispose();
    }
    for (var controller in _dropoffSlotControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _businessProfile = Map<String, dynamic>.from(response);
          _businessNameController.text = _businessProfile!['business_name'] ?? '';
          _businessAddressController.text = _businessProfile!['business_address'] ?? ''; // Load business address
          _latitude = _businessProfile!['latitude'];
          _longitude = _businessProfile!['longitude'];
          _latitudeController.text = _latitude?.toString() ?? '';
          _longitudeController.text = _longitude?.toString() ?? '';
          
          // Load laundry information
          _aboutUsController.text = _businessProfile!['about_business'] ?? '';
          _termsAndConditionsController.text = _businessProfile!['terms_and_conditions'] ?? ''; // Load terms and conditions
          _deliveryAvailable = _businessProfile!['does_delivery'] ?? false;
          
          // Load cover photo URL
          _coverPhotoUrl = _businessProfile!['cover_photo_url'];
          _coverPhotoUrl = _businessProfile!['cover_photo_url'];

          // Load open hours
          _openHoursController.text = _businessProfile!['open_hours_text'] ?? '';

          // Load available pickup and dropoff time slots
          // _pickupTimeController.text = _businessProfile!['available_pickup_time_slots']?.join(', ') ?? '';
          // _dropoffTimeController.text = _businessProfile!['available_dropoff_time_slots']?.join(', ') ?? '';

          _pickupSlotControllers.clear();
          final List<String> pickupSlots = List<String>.from(_businessProfile!['available_pickup_time_slots'] ?? []);
          for (var slot in pickupSlots) {
            _pickupSlotControllers.add(TextEditingController(text: slot));
          }

          _dropoffSlotControllers.clear();
          final List<String> dropoffSlots = List<String>.from(_businessProfile!['available_dropoff_time_slots'] ?? []);
          for (var slot in dropoffSlots) {
            _dropoffSlotControllers.add(TextEditingController(text: slot));
          }

          // Load services offered
          final servicesOffered = _businessProfile!['services_offered'];
          if (servicesOffered is List) {
            // Normalize service names when loading from database and remove duplicates
            _selectedServices = List<String>.from(servicesOffered.map((service) {
              if (service is String) {
                return service.toLowerCase() == 'deliver' ? 'Delivery' : service;
              }
              return service;
            }).whereType<String>().toSet().toList());
          } else if (servicesOffered is String) {
            _selectedServices = [servicesOffered.toLowerCase() == 'deliver' ? 'Delivery' : servicesOffered];
          }
          
          // Load pricelist
          final pricelistData = _businessProfile!['service_prices'];
          if (pricelistData is List) {
            _pricelist.clear();
            final uniquePricelist = <String, Map<String, dynamic>>{};
            for (var item in pricelistData) {
              if (item is Map<String, dynamic>) {
                String serviceName = item['service'] ?? '';
                double price = double.tryParse(item['price'].toString()) ?? 0.0;

                // Normalize service names when loading from database
                if (serviceName.toLowerCase() == 'deliver') {
                  serviceName = 'Delivery';
                }

                // Only add service if price is greater than 0.0
                if (price > 0.0) {
                  uniquePricelist[serviceName] = {
                    'service': serviceName,
                    'price': price.toStringAsFixed(2),
                  };
                }
              }
            }
            _pricelist.addAll(uniquePricelist.values);
          }
          
          // Load schedule if available
          if (_businessProfile!['pickup_schedule'] != null && _businessProfile!['dropoff_schedule'] != null) {
            _selectedSchedule = {
              'pickup': _businessProfile!['pickup_schedule'],
              'dropoff': _businessProfile!['dropoff_schedule'],
            };
          }
          
          // Sync services with pricelist to ensure all selected services have prices
          _syncServicesWithPricelist();
          
          
          // Initialize controllers for schedule
          for (var schedule in _weeklySchedule) {
            String day = schedule['day'];
            _openControllers[day] = TextEditingController(text: schedule['open']);
            _closeControllers[day] = TextEditingController(text: schedule['close']);
            _closedDays[day] = schedule['closed'] ?? false;
          }
          // Removed loading of weekly schedule
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  

  void _toggleService(String service) {
    // Normalize service name before processing
    String normalizedService = service.toLowerCase() == 'deliver' ? 'Delivery' : service;

    setState(() {
      if (_selectedServices.contains(normalizedService)) {
        // Remove service from selected services
        _selectedServices.remove(normalizedService);
        
        // Also remove from pricelist if it exists
        _pricelist.removeWhere((item) => item['service'] == normalizedService);
      } else {
        // Add service to selected services
        _selectedServices.add(normalizedService);
        
        // Check if service already exists in pricelist
        bool serviceExists = _pricelist.any((item) => item['service'] == normalizedService);
        
        // If not exists, add it with default price of 0.00
        if (!serviceExists) {
          _pricelist.add({
            'service': normalizedService,
            'price': '0.00',
          });
        }
      }
    });
  }

  // Removed _addPricelistItem function as per user request.
  // void _addPricelistItem() {
  //   if (_serviceNameController.text.trim().isNotEmpty && _priceController.text.trim().isNotEmpty) {
  //     setState(() {
  //       _pricelist.add({
  //         'service': _serviceNameController.text.trim(),
  //         'price': _priceController.text.trim(),
  //       });
  //       _serviceNameController.clear();
  //       _priceController.clear();
  //     });
  //   }
  // }

  void _removePricelistItem(int index) {
    setState(() {
      _pricelist.removeAt(index);
      // Clean up editing controllers if they exist
      _editServiceControllers.remove(index);
      _editPriceControllers.remove(index);
      _editingIndices.remove(index);
    });
  }

  void _startEditingPricelistItem(int index) {
    setState(() {
      _editingIndices.add(index);
      _editServiceControllers[index] = TextEditingController(text: _pricelist[index]['service']);
      _editPriceControllers[index] = TextEditingController(text: _pricelist[index]['price']);
    });
  }

  void _savePricelistItem(int index) {
    setState(() {
      _pricelist[index] = {
        'service': _editServiceControllers[index]!.text.trim(),
        'price': _editPriceControllers[index]!.text.trim(),
      };
      _editingIndices.remove(index);
      _editServiceControllers[index]!.dispose();
      _editPriceControllers[index]!.dispose();
      _editServiceControllers.remove(index);
      _editPriceControllers.remove(index);
    });
  }

  void _cancelEditingPricelistItem(int index) {
    setState(() {
      _editingIndices.remove(index);
      _editServiceControllers[index]!.dispose();
      _editPriceControllers[index]!.dispose();
      _editServiceControllers.remove(index);
      _editPriceControllers.remove(index);
    });
  }

  void _syncServicesWithPricelist() {
    setState(() {
      // Create a set of services that already have prices
      Set<String> existingServices = _pricelist.map((item) => item['service'] as String).toSet();
      
      // Add any missing selected services to pricelist with default price
      for (String service in _selectedServices) {
        // Normalize service name before checking/adding
        String normalizedService = service.toLowerCase() == 'deliver' ? 'Delivery' : service;

        if (!existingServices.contains(normalizedService)) {
          _pricelist.add({
            'service': normalizedService,
            'price': '0.00',
          });
        }
      }
      
      // Remove any services from pricelist that are no longer selected
      // Ensure comparison is done with normalized names
      _pricelist.removeWhere((item) => !_selectedServices.contains(item['service']));
    });
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // Specify that we only want image files
        allowMultiple: false,
        withData: true, // For web, get bytes
      );

      if (result != null) {
        setState(() {
          if (result.files.single.bytes != null) {
            // Web platform
            _selectedImageBytes = result.files.single.bytes;
            _selectedImageFile = null; // Clear file reference for web
          } else {
            // Mobile/Desktop platforms
            _selectedImageFile = File(result.files.single.path!);
            _selectedImageBytes = null; // Clear bytes reference for non-web
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Prepare update data
      Map<String, dynamic> updateData = {
        'business_name': _businessNameController.text.trim(),
        'business_address': _businessAddressController.text.trim(), // Save business address
        'latitude': _latitude,
        'longitude': _longitude,
        'about_business': _aboutUsController.text.trim(),
        'does_delivery': _deliveryAvailable,
        'terms_and_conditions': _termsAndConditionsController.text.trim(), // Save terms and conditions
        'services_offered': _selectedServices,
        'service_prices': _pricelist,
        'open_hours_text': _openHoursController.text.trim(), // Save open hours
        'available_pickup_time_slots': _pickupSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
        'available_dropoff_time_slots': _dropoffSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
      };

      // Add schedule if selected
      if (_selectedSchedule != null) {
        updateData['pickup_schedule'] = _selectedSchedule!['pickup'];
        updateData['dropoff_schedule'] = _selectedSchedule!['dropoff'];
      }

      // Upload new cover photo if selected
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        final String fileExtension = _selectedImageFile?.path.split('.').last ?? 'png';
        final String fileName = '${user.id}/cover_photo.$fileExtension';
        final String path = fileName;

        if (_selectedImageFile != null) {
          // For mobile/desktop
          final Uint8List imageBytes = await _selectedImageFile!.readAsBytes();
          await Supabase.instance.client.storage.from('business_photos').uploadBinary(
                path,
                imageBytes,
                fileOptions: const FileOptions(upsert: true),
              );
        } else if (_selectedImageBytes != null) {
          // For web
          await Supabase.instance.client.storage.from('business_photos').uploadBinary(
                path,
                _selectedImageBytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        }

        final String publicUrl = Supabase.instance.client.storage
            .from('business_photos')
            .getPublicUrl(path);
        updateData['cover_photo_url'] = publicUrl;
      }

      await Supabase.instance.client
          .from('business_profiles')
          .update(updateData)
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildServiceChip(String service) {
    final isSelected = _selectedServices.contains(service);
    
    return GestureDetector(
      onTap: () => _toggleService(service),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.remove : Icons.add,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              service,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build editable pricelist item
  Widget _buildEditablePricelistItem(int index) {
    final item = _pricelist[index];
    final isEditing = _editingIndices.contains(index);

    if (isEditing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _editServiceControllers[index],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Service name',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _editPriceControllers[index],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Price',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  prefixText: '₱',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _savePricelistItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => _cancelEditingPricelistItem(index),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['service'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${item['price']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _startEditingPricelistItem(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removePricelistItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B61FF)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Editable schedule section for owner
  Widget _buildEditableScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Open Hours'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _openHoursController,
          label: 'Open Hours (e.g., Mon-Sat: 9AM-5PM)',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your open hours';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        if (_deliveryAvailable) // Conditionally render based on _deliveryAvailable
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Pick-Up Time Slots'),
              const SizedBox(height: 12),
              Column(
                children: _pickupSlotControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: controller,
                            label: 'Pickup Slot ${index + 1}',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a pickup time slot';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _pickupSlotControllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, color: Color(0xFF7B61FF)),
                  label: const Text('Add Pickup Slot', style: TextStyle(color: Color(0xFF7B61FF))),
                  onPressed: () {
                    setState(() {
                      _pickupSlotControllers.add(TextEditingController());
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Drop-Off Time Slots'),
              const SizedBox(height: 12),
              Column(
                children: _dropoffSlotControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: controller,
                            label: 'Drop-Off Slot ${index + 1}',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a drop-off time slot';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _dropoffSlotControllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add, color: Color(0xFF7B61FF)),
                  label: const Text('Add Drop-Off Slot', style: TextStyle(color: Color(0xFF7B61FF))),
                  onPressed: () {
                    setState(() {
                      _dropoffSlotControllers.add(TextEditingController());
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'Business Profile',
          style: TextStyle(
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B61FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Create a temporary businessData map for preview
              final Map<String, dynamic> previewBusinessData = {
                'id': _businessProfile!['id'],
                'business_name': _businessNameController.text.trim(),
                'business_address': _businessAddressController.text.trim(),
                'latitude': _latitude,
                'longitude': _longitude,
                'about_business': _aboutUsController.text.trim(),
                'does_delivery': _deliveryAvailable,
                'terms_and_conditions': _termsAndConditionsController.text.trim(),
                'services_offered': _selectedServices,
                'service_prices': _pricelist,
                'open_hours_text': _openHoursController.text.trim(),
                'available_pickup_time_slots': _pickupSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
                'available_dropoff_time_slots': _dropoffSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
                'cover_photo_url': _coverPhotoUrl, // Pass existing URL
                // Pass the selected image file for preview if available
                '_coverPhotoFile': _selectedImageFile != null
                    ? PlatformFile(
                        name: _selectedImageFile!.path.split('/').last,
                        size: _selectedImageFile!.lengthSync(),
                        path: _selectedImageFile!.path,
                        bytes: kIsWeb ? _selectedImageBytes : null,
                      )
                    : null,
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessDetailScreen(
                    businessData: previewBusinessData,
                  ),
                ),
              );
            },
            child: const Text(
              'Preview',
              style: TextStyle(
                color: Color(0xFF7B61FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo Section
                    // Cover Photo Section
                             Container(
                               height: 200,
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 color: Colors.grey[200],
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Stack(
                                 children: [
                                   if (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty)
                                     ...[ // Wrap in a list and use spread operator
                                       Positioned.fill(
                                         child: ClipRRect(
                                           borderRadius: BorderRadius.circular(12),
                                           child: OptimizedImage(
                                             imageUrl: _coverPhotoUrl!,
                                             fit: BoxFit.cover,
                                           ),
                                         ),
                                       ),
                                     ]
                                   else if (_selectedImageBytes != null)
                                     ...[ // Wrap in a list and use spread operator
                                       Positioned.fill(
                                         child: ClipRRect(
                                           borderRadius: BorderRadius.circular(12),
                                           child: Image.memory(
                                             _selectedImageBytes!,
                                             fit: BoxFit.cover,
                                           ),
                                         ),
                                       ),
                                     ]
                                   else if (_selectedImageFile != null)
                                     ...[ // Wrap in a list and use spread operator
                                       Positioned.fill(
                                         child: ClipRRect(
                                           borderRadius: BorderRadius.circular(12),
                                           child: Image.file(
                                             _selectedImageFile!,
                                             fit: BoxFit.cover,
                                           ),
                                         ),
                                       ),
                                     ]
                                   else if (_coverPhotoUrl == null && _selectedImageBytes == null && _selectedImageFile == null)
                                     ...[ // Wrap in a list and use spread operator
                                       Center(
                                         child: Icon(
                                           Icons.photo,
                                           size: 50,
                                           color: Colors.grey[400],
                                         ),
                                       ),
                                     ], // Corrected comma placement: after the closing ']'
                                   Positioned.fill( // Make the button fill the entire container
                                     child: ElevatedButton.icon(
                                       onPressed: _pickImage,
                                       icon: const Icon(Icons.camera_alt, color: Colors.white),
                                       label: const Text('Change Cover Photo', style: TextStyle(color: Colors.white)),
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.grey.withOpacity(0.5), // Changed to grey with 50% opacity
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(12), // Match parent border radius
                                         ),
                                         padding: EdgeInsets.zero, // Remove default padding to fill completely
                                       ),
                                     ),
                                   ),
                                   ],
                                 ),
                               ),
                               const SizedBox(height: 20),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Business Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Your Shop\'s Exact Location'),
                    const SizedBox(height: 16),
                    // Business Address Field
                    TextFormField(
                      controller: _businessAddressController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Business Address',
                        labelStyle: const TextStyle(color: Colors.black),
                        hintText: 'Enter your business address',
                        prefixIcon: const Icon(Icons.location_on, color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map, color: Colors.black54),
                          onPressed: () async {
                            final LatLng? selectedLocation = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OwnerMapScreen(
                                  initialLatitude: _latitude,
                                  initialLongitude: _longitude,
                                ),
                              ),
                            );
                            
                            if (selectedLocation != null) {
                              setState(() {
                                _latitude = selectedLocation.latitude;
                                _longitude = selectedLocation.longitude;
                                _latitudeController.text = _latitude?.toString() ?? '';
                                _longitudeController.text = _longitude?.toString() ?? '';
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your business address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Latitude Field
                    TextFormField(
                      controller: _latitudeController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.location_on, color: Colors.black54),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter latitude';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _latitude = double.tryParse(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _longitudeController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.location_on, color: Colors.black54),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter longitude';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _longitude = double.tryParse(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _aboutUsController,
                      label: 'About Us',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // Not required anymore
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Delivery Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _deliveryAvailable,
                          onChanged: (value) {
                            setState(() {
                              _deliveryAvailable = value;
                            });
                          },
                          activeColor: const Color(0xFF7B61FF),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    
                    // 3. Services Offered Section
                    _buildSectionHeader('Services Offered'),
                    const SizedBox(height: 16),
                    const Text(
                      'Select services you offer:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: _availableServices.map((service) => _buildServiceChip(service)).toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // 3. Business Schedule Section (Editable)
                    _buildSectionHeader('Business Schedule'),
                    const SizedBox(height: 16),
                    _buildEditableScheduleSection(),
                    const SizedBox(height: 32),
                    
                    // 5. Pricelist Section - Now Editable
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Pricelist'),
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.blue),
                          onPressed: _syncServicesWithPricelist,
                          tooltip: 'Sync services with pricelist',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Removed input fields for service name and price, and the 'Plus' button
                    // as per user request. The sync button is kept for now.
                    // Row(
                    //   children: [
                    //     const Spacer(), // To push the sync button to the right if needed
                    //     IconButton(
                    //       icon: const Icon(Icons.sync, color: Colors.blue),
                    //       onPressed: _syncServicesWithPricelist,
                    //       tooltip: 'Sync services with pricelist',
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                    
                    // Display editable pricelist
                    if (_pricelist.isNotEmpty) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pricelist.length,
                        itemBuilder: (context, index) {
                          return _buildEditablePricelistItem(index);
                        },
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'No pricelist items added yet. Add some above.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Terms and Conditions Section
                    _buildSectionHeader('Terms and Conditions'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _termsAndConditionsController,
                      label: 'Terms and Conditions',
                      maxLines: 5,
                      validator: (value) {
                        return null; // Optional field
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6. Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B61FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}