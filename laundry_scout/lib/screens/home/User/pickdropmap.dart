import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:laundry_scout/services/location_service.dart';

class PickDropMapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PickDropMapScreen({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<PickDropMapScreen> createState() => _PickDropMapScreenState();
}

class _PickDropMapScreenState extends State<PickDropMapScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _hasPermission = false;
  String _permissionStatus = 'Checking permission...';
  final MapController _mapController = MapController();
  
  // User information fields
  String _fullName = '';
  String _phoneNumber = '';
  String _currentAddress = '';
  bool _isEditingPhone = false;
  bool _isEditingName = false;
  bool _isEditingAddress = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _checkLocationPermission();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('user_profiles')
            .select('first_name, last_name, mobile_number, current_address')
            .eq('id', user.id)
            .single();
        
        setState(() {
          String firstName = userData['first_name'] ?? '';
          String lastName = userData['last_name'] ?? '';
          _fullName = '$firstName $lastName'.trim();
          _phoneNumber = userData['mobile_number'] ?? '';
          _currentAddress = userData['current_address'] ?? '';
          _phoneController.text = _phoneNumber;
          _addressController.text = _currentAddress;
          _nameController.text = _fullName;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
      _permissionStatus = 'Checking permission...';
    });

    final permissionGranted = await LocationService.requestLocationPermission();
    
    if (permissionGranted) {
      setState(() {
        _hasPermission = true;
        _permissionStatus = 'Location permission granted';
      });
      await _getCurrentLocation();
    } else {
      final status = await Permission.location.status;
      setState(() {
        _hasPermission = false;
        if (status.isDenied) {
          _permissionStatus = 'Location permission denied';
        } else if (status.isPermanentlyDenied) {
          _permissionStatus = 'Location permission permanently denied. Please enable in settings.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      
      setState(() {
        if (position != null) {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _selectedPosition = _currentPosition; // Keep both positions in sync
          _mapController.move(_selectedPosition!, 15.0); // Move map to current location
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedPosition = latlng;
      _currentPosition = latlng; // Update current position when user selects a location
    });
  }

  void _requestPermissionAgain() {
    _checkLocationPermission();
  }

  Future<void> _saveLocationToSupabase() async {
    if (_selectedPosition != null) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Parse full name into first and last name
          List<String> nameParts = _fullName.trim().split(' ');
          String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          await Supabase.instance.client
              .from('user_profiles')
              .update({
                'latitude': _selectedPosition!.latitude,
                'longitude': _selectedPosition!.longitude,
                'mobile_number': _phoneNumber,
                'current_address': _currentAddress,
                'first_name': firstName,
                'last_name': lastName,
              })
              .eq('id', user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location and contact info saved successfully!')),
            );
            // Return to the order placement screen with the selected location
            Navigator.of(context).pop(_selectedPosition);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving data: $e')),
          );
        }
      }
    }
  }

  void _togglePhoneEdit() {
    setState(() {
      _isEditingPhone = !_isEditingPhone;
      if (!_isEditingPhone) {
        _phoneNumber = _phoneController.text;
      }
    });
  }

  void _toggleNameEdit() {
    setState(() {
      _isEditingName = !_isEditingName;
      if (!_isEditingName) {
        _fullName = _nameController.text;
      }
    });
  }

  void _toggleAddressEdit() {
    setState(() {
      _isEditingAddress = !_isEditingAddress;
      if (!_isEditingAddress) {
        _currentAddress = _addressController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: const Color(0xFF5A35E3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: const Color(0xFF5A35E3),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.check, color: const Color(0xFF5A35E3)),
                onPressed: _saveLocationToSupabase,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : _buildMapView(),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5A35E3),
            const Color(0xFF5A35E3).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Location Permission Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _permissionStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _requestPermissionAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5A35E3),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedPosition ?? const LatLng(0, 0),
            initialZoom: 15.0,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),

            if (_selectedPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF5A35E3),
                      size: 28,
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        // Draggable bottom sheet for user info
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (BuildContext context, ScrollController scrollController) {
            _scrollController = scrollController;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A35E3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Name Field
                    _buildInfoField(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: _fullName,
                      isEditable: true,
                      controller: _nameController,
                      isEditing: _isEditingName,
                      onEdit: _toggleNameEdit,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone Field
                    _buildInfoField(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: _phoneNumber,
                      isEditable: true,
                      controller: _phoneController,
                      isEditing: _isEditingPhone,
                      onEdit: _togglePhoneEdit,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address Field
                    _buildInfoField(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _currentAddress,
                      isEditable: true,
                      controller: _addressController,
                      isEditing: _isEditingAddress,
                      onEdit: _toggleAddressEdit,
                      maxLines: 2,
                      onChanged: (value) => _currentAddress = value,
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Current Location Button
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 80,
          child: FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF5A35E3),
            mini: true,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    TextEditingController? controller,
    bool isEditing = false,
    VoidCallback? onEdit,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5A35E3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5A35E3), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditable && controller != null && !isEditing && onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value.isEmpty ? 'Not provided' : value,
                            style: TextStyle(
                              fontSize: 16,
                              color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  )
                else if (isEditable && controller != null && isEditing)
                  TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter $label',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    maxLines: maxLines,
                    onChanged: onChanged,
                    autofocus: true,
                  )
                else if (isEditable && controller != null && onChanged != null && onEdit == null)
                  TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter $label',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    maxLines: maxLines,
                    onChanged: onChanged,
                  )
                else
                  Text(
                    value.isEmpty ? 'Not provided' : value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}