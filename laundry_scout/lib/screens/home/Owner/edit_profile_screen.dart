import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/optimized_image.dart';
import '../User/schedule_selection_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Laundry Information controllers
  final _aboutUsController = TextEditingController();
  final _openHoursController = TextEditingController();
  
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
  final _serviceNameController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Controllers for editing existing pricelist items
  final Map<int, TextEditingController> _editServiceControllers = {};
  final Map<int, TextEditingController> _editPriceControllers = {};
  final Set<int> _editingIndices = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _deliveryAvailable = false;
  Map<String, dynamic>? _businessProfile;
  Map<String, String>? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutUsController.dispose();
    _openHoursController.dispose();
    _serviceNameController.dispose();
    _priceController.dispose();
    
    // Dispose editing controllers
    for (var controller in _editServiceControllers.values) {
      controller.dispose();
    }
    for (var controller in _editPriceControllers.values) {
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
          _emailController.text = _businessProfile!['email'] ?? '';
          _phoneController.text = _businessProfile!['business_phone_number'] ?? '';
          
          // Load laundry information
          _aboutUsController.text = _businessProfile!['about_business'] ?? '';
          _openHoursController.text = _businessProfile!['open_hours'] ?? '';
          _deliveryAvailable = _businessProfile!['does_delivery'] ?? false;
          
          // Load services offered
          final servicesOffered = _businessProfile!['services_offered'];
          if (servicesOffered is List) {
            _selectedServices = List<String>.from(servicesOffered);
          } else if (servicesOffered is String) {
            _selectedServices = [servicesOffered];
          }
          
          // Load pricelist
          final pricelistData = _businessProfile!['service_prices'];
          if (pricelistData is List) {
            _pricelist.clear();
            for (var item in pricelistData) {
              if (item is Map<String, dynamic>) {
                _pricelist.add({
                  'service': item['service'] ?? '',
                  'price': item['price'] ?? '',
                });
              }
            }
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
    setState(() {
      if (_selectedServices.contains(service)) {
        // Remove service from selected services
        _selectedServices.remove(service);
        
        // Also remove from pricelist if it exists
        _pricelist.removeWhere((item) => item['service'] == service);
      } else {
        // Add service to selected services
        _selectedServices.add(service);
        
        // Check if service already exists in pricelist
        bool serviceExists = _pricelist.any((item) => item['service'] == service);
        
        // If not exists, add it with default price of 0.00
        if (!serviceExists) {
          _pricelist.add({
            'service': service,
            'price': '0.00',
          });
        }
      }
    });
  }

  void _addPricelistItem() {
    if (_serviceNameController.text.trim().isNotEmpty && _priceController.text.trim().isNotEmpty) {
      setState(() {
        _pricelist.add({
          'service': _serviceNameController.text.trim(),
          'price': _priceController.text.trim(),
        });
        _serviceNameController.clear();
        _priceController.clear();
      });
    }
  }

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
        if (!existingServices.contains(service)) {
          _pricelist.add({
            'service': service,
            'price': '0.00',
          });
        }
      }
      
      // Remove any services from pricelist that are no longer selected
      _pricelist.removeWhere((item) => !_selectedServices.contains(item['service']));
    });
  }

  Future<void> _selectSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleSelectionScreen(
          selectedSchedule: _selectedSchedule,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _selectedSchedule = result;
      });
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
        'email': _emailController.text.trim(),
        'business_phone_number': _phoneController.text.trim(),
        'about_business': _aboutUsController.text.trim(),
        'open_hours': _openHoursController.text.trim(),
        'does_delivery': _deliveryAvailable,
        'services_offered': _selectedServices,
        'service_prices': _pricelist,
      };

      // Add schedule if selected
      if (_selectedSchedule != null) {
        updateData['pickup_schedule'] = _selectedSchedule!['pickup'];
        updateData['dropoff_schedule'] = _selectedSchedule!['dropoff'];
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
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: _businessProfile?['cover_photo_url'] != null
                            ? ClipOval(
                                child: OptimizedImage(
                                  imageUrl: _businessProfile!['cover_photo_url'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 1. Business Information Section
                    _buildSectionHeader('Business Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // Not required anymore
                        }
                        if (!RegExp(r'^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // Not required anymore
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // 2. Laundry Information Section
                    _buildSectionHeader('Laundry Information'),
                    const SizedBox(height: 16),
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
                    _buildTextField(
                      controller: _openHoursController,
                      label: 'Open Hours',
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
                    
                    // 4. Business Schedule Section
                    _buildSectionHeader('Business Schedule'),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectSchedule,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedSchedule != null
                                    ? 'Pickup: ${_selectedSchedule!['pickup']}\nDropoff: ${_selectedSchedule!['dropoff']}'
                                    : 'Edit pickup and dropoff schedule',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedSchedule != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const Icon(Icons.edit, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 5. Pricelist Section - Now Editable
                    _buildSectionHeader('Pricelist'),
                    const SizedBox(height: 16),
                    
                    // Add new pricelist item
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serviceNameController,
                            decoration: InputDecoration(
                              hintText: 'Service name',
                              hintStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              hintText: 'Price',
                              hintStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              prefixText: '₱',
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF7B61FF)),
                          onPressed: _addPricelistItem,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.blue),
                          onPressed: _syncServicesWithPricelist,
                          tooltip: 'Sync services with pricelist',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
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
                    
                    // Save Button
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