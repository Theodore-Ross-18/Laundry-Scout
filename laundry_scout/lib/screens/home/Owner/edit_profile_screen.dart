import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart'; 
import 'dart:typed_data';
import 'dart:io';
import '../../../widgets/optimized_image.dart';
import 'package:laundry_scout/screens/home/Owner/owner_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:laundry_scout/screens/home/User/business_detail_screen.dart'; // Import for BusinessDetailScreen
import 'package:laundry_scout/screens/home/Owner/image_preview_screen.dart'; // Import for ImagePreviewScreen
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final _termsAndConditionsController = TextEditingController();
  final _customServiceController = TextEditingController();
  final TextEditingController _deliveryFeeController = TextEditingController(); // Add this line
  
  final List<String> _availableServices = [
    'Iron Only',
    'Wash & Fold',
    'Clean & Iron',
  ];
  List<String> _selectedServices = [];
  
  
  final List<Map<String, dynamic>> _pricelist = [];
  final Map<int, TextEditingController> _editServiceControllers = {};
  final Map<int, TextEditingController> _editPriceControllers = {};
  final Set<int> _editingIndices = {};
  // List<Map<String, dynamic>> _weeklySchedule = []; // Removed
  // final Map<String, TextEditingController> _openControllers = {}; // Removed
  // final Map<String, TextEditingController> _closeControllers = {}; // Removed
  // final Map<String, bool> _closedDays = {}; // Removed
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _deliveryAvailable = false;
  bool _isUploadingImages = false;
  double _deliveryFee = 0.0; // Add this line

  Map<String, dynamic>? _businessProfile;
  // Map<String, String>? _selectedSchedule; // Removed

  // final _openHoursController = TextEditingController(); // Removed
  final _pickupTimeController = TextEditingController();
  final _dropoffTimeController = TextEditingController();

  final List<TextEditingController> _pickupSlotControllers = [];
  final List<TextEditingController> _dropoffSlotControllers = [];

  File? _selectedImageFile; 
  Uint8List? _selectedImageBytes; 
  String? _coverPhotoUrl;
  List<File> _selectedGalleryImageFiles = [];
  List<Uint8List> _selectedGalleryImageBytes = [];
  List<String> _existingGalleryImageUrls = []; 

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
    _customServiceController.dispose();
    _deliveryFeeController.dispose(); // Add this line
   
    for (var controller in _editServiceControllers.values) {
      controller.dispose();
    }
    for (var controller in _editPriceControllers.values) {
      controller.dispose();
    }
    
    // for (var c in _openControllers.values) { // Removed
    //   c.dispose(); // Removed
    // } // Removed
    // for (var c in _closeControllers.values) { // Removed
    //   c.dispose(); // Removed
    // } // Removed
    
    // _openHoursController.dispose();
    _pickupTimeController.dispose();
    _dropoffTimeController.dispose();

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
      
          _aboutUsController.text = _businessProfile!['about_business'] ?? '';
          _termsAndConditionsController.text = _businessProfile!['terms_and_conditions'] ?? ''; // Load terms and conditions
          _deliveryAvailable = _businessProfile!['does_delivery'] ?? false;
          _deliveryFee = double.tryParse(_businessProfile!['delivery_fee'].toString()) ?? 0.0;
          _deliveryFeeController.text = _deliveryFee.toString(); // Add this line

          final List<dynamic> galleryUrls = _businessProfile!['gallery_image_urls'] ?? [];
          _existingGalleryImageUrls = List<String>.from(galleryUrls.map((url) => url.toString()));
          _coverPhotoUrl = _businessProfile!['cover_photo_url'];

          // _openHoursController.text = _businessProfile!['open_hours'] ?? ''; // Removed

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

          final servicesOffered = _businessProfile!['services_offered'];
          if (servicesOffered is List) {
            _selectedServices = List<String>.from(servicesOffered.map((service) {
              if (service is String) {
                return service.toLowerCase() == 'deliver' ? 'Delivery' : service;
              }
              return service;
            }).whereType<String>().toSet().toList());

            // Add loaded services to _availableServices, avoiding duplicates
            setState(() {
              for (var service in _selectedServices) {
                if (!_availableServices.contains(service)) {
                  _availableServices.add(service);
                }
              }
            });
          } else if (servicesOffered is String) {
            _selectedServices = [servicesOffered.toLowerCase() == 'deliver' ? 'Delivery' : servicesOffered];
            setState(() {
              if (!_availableServices.contains(_selectedServices[0])) {
                _availableServices.add(_selectedServices[0]);
              }
            });
          }
          
          // Load all available services, including custom ones
          final allAvailableServicesData = _businessProfile!['all_available_services'];
          if (allAvailableServicesData is List) {
            setState(() {
              // Ensure default services are always present
              final List<String> defaultServices = [
                'Iron Only',
                'Wash & Fold',
                'Clean & Iron',
              ];
              _availableServices.clear();
              _availableServices.addAll(defaultServices);
              
              for (var service in allAvailableServicesData) {
                if (service is String && !_availableServices.contains(service)) {
                  _availableServices.add(service);
                }
              }
            });
          }
          
          final pricelistData = _businessProfile!['service_prices'];
          if (pricelistData is List) {
            _pricelist.clear();
            final uniquePricelist = <String, Map<String, dynamic>>{};
            for (var item in pricelistData) {
              if (item is Map<String, dynamic>) {
                String serviceName = item['service'] ?? '';
                double price = double.tryParse(item['price'].toString()) ?? 0.0;

                if (serviceName.toLowerCase() == 'deliver') {
                  serviceName = 'Delivery';
                }

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
          
          // if (_businessProfile!['pickup_schedule'] != null && _businessProfile!['dropoff_schedule'] != null) { // Removed
          //   _selectedSchedule = { // Removed
          //     'pickup': _businessProfile!['pickup_schedule'], // Removed
          //     'dropoff': _businessProfile!['dropoff_schedule'], // Removed
          //   }; // Removed
          // } // Removed
          
          _syncServicesWithPricelist();
          
          // for (var schedule in _weeklySchedule) { // Removed
          //   String day = schedule['day']; // Removed
          //   _openControllers[day] = TextEditingController(text: schedule['open']); // Removed
          //   _closeControllers[day] = TextEditingController(text: schedule['close']); // Removed
          //   _closedDays[day] = schedule['closed'] ?? false; // Removed
          // } // Removed
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
  
    String normalizedService = service.toLowerCase() == 'deliver' ? 'Delivery' : service;

    setState(() {
      if (_selectedServices.contains(normalizedService)) {
       
        _selectedServices.remove(normalizedService);
        
      
        _pricelist.removeWhere((item) => item['service'] == normalizedService);
      } else {
        
        _selectedServices.add(normalizedService);
        
        
        bool serviceExists = _pricelist.any((item) => item['service'] == normalizedService);
        
       
        if (!serviceExists) {
          _pricelist.add({
            'service': normalizedService,
            'price': '0.00',
          });
        }
      }
    });
  }

  void _removePricelistItem(int index) {
    setState(() {
      _pricelist.removeAt(index);
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
      
      Set<String> existingServices = _pricelist.map((item) => item['service'] as String).toSet();
      
      final List<dynamic> originalServicePrices = _businessProfile!['service_prices'] ?? [];
      final Map<String, String> originalPricesMap = {
        for (var item in originalServicePrices)
          if (item is Map<String, dynamic> && item['service'] is String && item['price'] != null)
            (item['service'] as String).toLowerCase() == 'deliver' ? 'Delivery' : item['service'] as String: item['price'].toString()
      };

      for (String service in _selectedServices) {
        String normalizedService = service.toLowerCase() == 'deliver' ? 'Delivery' : service;

        if (!existingServices.contains(normalizedService)) {
          _pricelist.add({
            'service': normalizedService,
            'price': originalPricesMap[normalizedService] ?? '0.00',
          });
        }
      }
      
      _pricelist.removeWhere((item) {
        String normalizedPricelistService = (item['service'] as String).toLowerCase() == 'deliver' ? 'Delivery' : item['service'] as String;
        return !_selectedServices.contains(normalizedPricelistService);
      });
    });
  }

  
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, 
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          if (result.files.single.bytes != null) {
            
            _selectedImageBytes = result.files.single.bytes;
            _selectedImageFile = null; 
          } else {
            
            _selectedImageFile = File(result.files.single.path!);
            _selectedImageBytes = null;
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

  Future<void> _pickGalleryImages() async { 
    try { 
      FilePickerResult? result = await FilePicker.platform.pickFiles( 
        type: FileType.image, 
        allowMultiple: true, 
        withData: true, 
      ); 

      if (result != null) { 
        setState(() { 
          for (var file in result.files) { 
            if (_selectedGalleryImageFiles.length + _existingGalleryImageUrls.length + _selectedGalleryImageBytes.length < 7) { 
              if (file.bytes != null) { 
                _selectedGalleryImageBytes.add(file.bytes!); 
              } else if (file.path != null) { 
                _selectedGalleryImageFiles.add(File(file.path!)); 
              } 
            } else { 
              ScaffoldMessenger.of(context).showSnackBar( 
                const SnackBar(content: Text('You can only upload a maximum of 7 gallery images.')), 
              ); 
            } 
          } 
        }); 
      } 
    } catch (e) { 
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar(content: Text('Error picking gallery images: $e')), 
        ); 
      } 
    } 
  } 

  Widget _buildGalleryImagePreview(dynamic imageSource, {required bool isNew}) { 
    Widget imageWidget; 
    if (imageSource is String) { 
      imageWidget = OptimizedImage( 
        imageUrl: imageSource, 
        fit: BoxFit.cover, 
      ); 
    } else if (imageSource is File) { 
      imageWidget = Image.file( 
        imageSource, 
        fit: BoxFit.cover, 
      ); 
    } else if (imageSource is Uint8List) { 
      imageWidget = Image.memory( 
        imageSource, 
        fit: BoxFit.cover, 
      ); 
    } else { 
      return const SizedBox.shrink(); 
    } 

    return Stack( 
      children: [ 
        GestureDetector( 
          onTap: () { 
            if (imageSource is String) { 
              Navigator.push( 
                context, 
                MaterialPageRoute( 
                  builder: (context) => ImagePreviewScreen(imageUrl: imageSource), 
                ), 
              ); 
            } 
          }, 
          child: Hero( 
            tag: imageSource.hashCode, // Unique tag for Hero animation 
            child: Container( 
              width: 100, 
              height: 100, 
              decoration: BoxDecoration( 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: Colors.grey[300]!), 
              ), 
              child: ClipRRect( 
                borderRadius: BorderRadius.circular(8), 
                child: imageWidget, 
              ), 
            ), 
          ), 
        ), 
        Positioned( 
          top: 0, 
          right: 0, 
          child: GestureDetector( 
            onTap: () { 
              setState(() { 
                if (isNew) { 
                  if (imageSource is File) { 
                    _selectedGalleryImageFiles.remove(imageSource); 
                  } else if (imageSource is Uint8List) { 
                    _selectedGalleryImageBytes.remove(imageSource); 
                  } 
                } else { 
                  _existingGalleryImageUrls.remove(imageSource); 
                } 
              }); 
            }, 
            child: Container( 
              decoration: BoxDecoration( 
                color: Colors.black54, 
                borderRadius: BorderRadius.circular(10), 
              ), 
              child: const Icon( 
                Icons.close, 
                color: Colors.white, 
                size: 18, 
              ), 
            ), 
          ), 
        ), 
      ], 
    ); 
  }

  Future<void> _deleteCoverPhoto() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (_coverPhotoUrl != null) {
        final uri = Uri.parse(_coverPhotoUrl!);
        final segments = uri.pathSegments;
        final profilesIndex = segments.indexOf('profiles');
        String? filePath;
        if (profilesIndex != -1 && profilesIndex + 1 < segments.length) {
          filePath = segments.sublist(profilesIndex + 1).join('/');
        }

        if (filePath != null) {
          await Supabase.instance.client.storage.from('profiles').remove([filePath]);
        }
      }

      await Supabase.instance.client
          .from('business_profiles')
          .update({'cover_photo_url': null})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _coverPhotoUrl = null;
          _selectedImageFile = null;
          _selectedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover photo deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting cover photo: $e'),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      Map<String, dynamic> updateData = {
        'business_name': _businessNameController.text.trim(),
        'business_address': _businessAddressController.text.trim(), 
        'latitude': _latitude,
        'longitude': _longitude,
        'about_business': _aboutUsController.text.trim(),
        'does_delivery': _deliveryAvailable,
        'terms_and_conditions': _termsAndConditionsController.text.trim(),
        'delivery_fee': _deliveryAvailable ? double.tryParse(_deliveryFeeController.text.trim()) : null,
        'service_prices': _pricelist,
        'services_offered': _selectedServices,
        'all_available_services': _availableServices,

        'available_pickup_time_slots': _pickupSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
        'available_dropoff_time_slots': _dropoffSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
      };

      if (_selectedImageFile != null || _selectedImageBytes != null) {
        final String fileExtension = _selectedImageFile?.path.split('.').last ?? 'png';
        final String fileName = '${user.id}/cover_photo.$fileExtension';
        final String path = fileName;

        if (_selectedImageFile != null) {
       
          final Uint8List imageBytes = await _selectedImageFile!.readAsBytes();
          await Supabase.instance.client.storage.from('profiles').uploadBinary(
                path,
                imageBytes,
                fileOptions: const FileOptions(upsert: true),
              );
        } else if (_selectedImageBytes != null) {
        
          await Supabase.instance.client.storage.from('profiles').uploadBinary(
                path,
                _selectedImageBytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        }

        final String publicUrl = Supabase.instance.client.storage
            .from('profiles')
            .getPublicUrl(path);
        updateData['cover_photo_url'] = publicUrl;
      }

      List<String> newGalleryImageUrls = [];
      for (var i = 0; i < _selectedGalleryImageFiles.length; i++) {
        final file = _selectedGalleryImageFiles[i];
        final String fileExtension = file.path.split('.').last;
        final String fileName = '${user.id}/gallery_photo_${DateTime.now().millisecondsSinceEpoch}_$i.$fileExtension';
        final String path = fileName;

        await Supabase.instance.client.storage.from('profiles').uploadBinary(
              path,
              await file.readAsBytes(),
              fileOptions: const FileOptions(upsert: true),
            );
        final String publicUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(path);
        newGalleryImageUrls.add(publicUrl);
      }

      for (var i = 0; i < _selectedGalleryImageBytes.length; i++) {
        final bytes = _selectedGalleryImageBytes[i];
        final String fileName = '${user.id}/gallery_photo_${DateTime.now().millisecondsSinceEpoch}_${_selectedGalleryImageFiles.length + i}.png';
        final String path = fileName;

        await Supabase.instance.client.storage.from('profiles').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        final String publicUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(path);
        newGalleryImageUrls.add(publicUrl);
      }

      updateData['gallery_image_urls'] = [..._existingGalleryImageUrls, ...newGalleryImageUrls];

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

  Widget _buildServiceChip(String service, [bool isCustom = false]) {
    final isSelected = _selectedServices.contains(service);
    
    return GestureDetector(
      onTap: () => _toggleService(service),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A35E3): Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[300]!,
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
            if (isCustom)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _availableServices.remove(service);
                    _selectedServices.remove(service);
                    _pricelist.removeWhere((item) => item['service'] == service);
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.cancel,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
          borderSide: const BorderSide(color: Color(0xFF5A35E3)),
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

  Widget _buildEditableScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        if (_deliveryAvailable)
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
                  icon: const Icon(Icons.add, color: Color(0xFF5A35E3)),
                  label: const Text('Add Pickup Slot', style: TextStyle(color: Color(0xFF5A35E3))),
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
                  icon: const Icon(Icons.add, color: Color(0xFF5A35E3)),
                  label: const Text('Add Drop-Off Slot', style: TextStyle(color: Color(0xFF5A35E3))),
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
            color: Color(0xFF5A35E3),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A35E3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
            
              final Map<String, dynamic> previewBusinessData = {
                'id': _businessProfile!['id'],
                'business_name': _businessNameController.text.trim(),
                'business_address': _businessAddressController.text.trim(),
                'latitude': _latitude,
                'longitude': _longitude,
                'about_business': _aboutUsController.text.trim(),
                'does_delivery': _deliveryAvailable,
                'terms_and_conditions': _termsAndConditionsController.text.trim(),
                'service_prices': _pricelist,

                'available_pickup_time_slots': _pickupSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
                'available_dropoff_time_slots': _dropoffSlotControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList(),
                'cover_photo_url': _coverPhotoUrl,
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
                color: Color(0xFF5A35E3),
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
                    
                             Container(
                               height: 200,
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 color: Colors.grey[200],
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Stack(
                                 children: [
                                   if (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty) ...[
                                     Positioned.fill(
                                       child: ClipRRect(
                                         borderRadius: BorderRadius.circular(12),
                                         child: OptimizedImage(
                                           imageUrl: _coverPhotoUrl!,
                                           fit: BoxFit.cover,
                                         ),
                                       ),
                                     ),
                                     Positioned(
                                       top: 8,
                                       right: 8,
                                       child: IconButton(
                                         icon: const Icon(Icons.delete_forever, color: Colors.red, size: 30),
                                         onPressed: _deleteCoverPhoto,
                                       ),
                                     ),
                                   ] else if (_selectedImageBytes != null) ...[
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
                                     ...[
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
                                     ...[
                                       Center(
                                         child: Icon(
                                           Icons.photo,
                                           size: 50,
                                           color: Colors.grey[400],
                                         ),
                                       ),
                                     ], 
                                   Positioned.fill( 
                                     child: ElevatedButton.icon(
                                       onPressed: _pickImage,
                                       icon: const Icon(Icons.camera_alt, color: Colors.white),
                                       label: const Text('Change Cover Photo', style: TextStyle(color: Colors.white)),
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.grey.withOpacity(0.5),
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                         padding: EdgeInsets.zero,
                                       ),
                                     ),
                                   ),
                                   if (_coverPhotoUrl != null || _selectedImageFile != null || _selectedImageBytes != null)
                                     Positioned(
                                       top: 8,
                                       right: 8,
                                       child: IconButton(
                                         icon: const Icon(Icons.delete_forever, color: Colors.red, size: 30),
                                         onPressed: _deleteCoverPhoto,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               const SizedBox(height: 20),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Business Information'),
                    // Gallery Image Upload 
                    const SizedBox(height: 20), 
                    _buildSectionHeader('Gallery Images'), 
                    const SizedBox(height: 10), 
                    Wrap( 
                      spacing: 8.0, 
                      runSpacing: 8.0, 
                      children: [ 
                        ..._existingGalleryImageUrls.map((url) => _buildGalleryImagePreview(url, isNew: false)), 
                        ..._selectedGalleryImageFiles.map((file) => _buildGalleryImagePreview(file, isNew: true)), 
                        ..._selectedGalleryImageBytes.map((bytes) => _buildGalleryImagePreview(bytes, isNew: true)), 
                        if (_selectedGalleryImageFiles.length + _existingGalleryImageUrls.length + _selectedGalleryImageBytes.length < 7) 
                          GestureDetector( 
                            onTap: _pickGalleryImages, 
                            child: Container( 
                              width: 100, 
                              height: 100, 
                              decoration: BoxDecoration( 
                                color: Colors.grey[200], 
                                borderRadius: BorderRadius.circular(8), 
                                border: Border.all(color: Colors.grey[300]!), 
                              ), 
                              child: const Icon( 
                                Icons.add_a_photo, 
                                color: Colors.grey, 
                                size: 40, 
                              ), 
                            ), 
                          ), 
                      ], 
                    ), 
                    if (_isUploadingImages) 
                      const Padding( 
                        padding: EdgeInsets.symmetric(vertical: 16.0), 
                        child: Row( 
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [ 
                            CircularProgressIndicator(), 
                            SizedBox(width: 16), 
                            Text('Uploading images...'), 
                          ], 
                        ), 
                      ),
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
                    _buildTextField(
                      controller: _aboutUsController,
                      label: 'About Us',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
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
                          activeColor: const Color(0xFF5A35E3),
                        ),
                      ],
                    ),
                    if (_deliveryAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: _deliveryFeeController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Fee',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(color: Colors.black),
                          ),
                          style: TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a delivery fee';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      
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
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableServices.map((service) => _buildServiceChip(service, true)).toList(),
                    ),
                    const SizedBox(height: 16),
                  
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customServiceController,
                            decoration: InputDecoration(
                              labelText: 'Add Custom Service',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF5A35E3), size: 36),
                          onPressed: () {
                            final String newService = _customServiceController.text.trim();
                            if (newService.isNotEmpty && !_availableServices.contains(newService)) {
                              setState(() {
                                _availableServices.add(newService);
                                _selectedServices.add(newService);
                                _pricelist.add({'service': newService, 'price': '0.00'});
                                _customServiceController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // 3. Business Schedule Section (Editable)
                    
                    const SizedBox(height: 16),
                    _buildEditableScheduleSection(),
                    const SizedBox(height: 32),
                    
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
            
                    _buildSectionHeader('Terms and Conditions'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _termsAndConditionsController,
                      label: 'Terms and Conditions',
                      maxLines: 5,
                      validator: (value) {
                        return null; 
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
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