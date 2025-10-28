import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_selection_screen.dart';
import 'schedule_selection_screen.dart';
import 'order_confirmation_screen.dart';
import 'package:laundry_scout/screens/home/User/pickdropmap.dart';
import 'package:latlong2/latlong.dart'; 

class OrderPlacementScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final List<String> availablePickupTimeSlots; 
  final List<String> availableDropoffTimeSlots; 

  const OrderPlacementScreen({
    super.key,
    required this.businessData,
    required this.availablePickupTimeSlots, 
    required this.availableDropoffTimeSlots, 
  });

  @override
  State<OrderPlacementScreen> createState() => _OrderPlacementScreenState();
}

class _OrderPlacementScreenState extends State<OrderPlacementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  String? _selectedAddress;
  Map<String, String>? _selectedSchedule;
  Map<String, int> _selectedServices = {}; 
  List<Map<String, dynamic>> _pricelist = []; 
  bool _isExpanded = false; 
  String _specialInstructions = ''; 
  Map<String, dynamic>? _businessProfile; 
  bool _isLoading = true;
  bool _isTermsExpanded = false; 
  
  final TextEditingController _currentAddressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  String? _firstName; 
  String? _lastName; 
  String? _phoneNumber; // Declared here
  final TextEditingController _fullNameController = TextEditingController(); 
  final TextEditingController _phoneNumberController = TextEditingController(); // Declared here

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadBusinessProfile(); 
  }

  @override
  void dispose() {
    _addressController.dispose();
    _specialInstructionsController.dispose();
    _currentAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _fullNameController.dispose(); 
    _phoneNumberController.dispose(); // Dispose here
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', widget.businessData['id'])
          .single();
      if (mounted) {
        setState(() {
          _businessProfile = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business profile: $e')),
        );
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('latitude, longitude, first_name, last_name, mobile_number')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _latitude = userProfile['latitude'];
            _longitude = userProfile['longitude'];
                  _latitudeController.text = _latitude?.toString() ?? '';
            _longitudeController.text = _longitude?.toString() ?? '';
            _firstName = userProfile['first_name']; 
            _lastName = userProfile['last_name'];
            _phoneNumber = userProfile['mobile_number']; // Add this line
            _fullNameController.text = '${_firstName ?? ''} ${_lastName ?? ''}';
            _phoneNumberController.text = _phoneNumber ?? ''; // Add this line
          });
        }

        final userAddressResponse = await Supabase.instance.client
            .from('user_profiles')
            .select('current_address')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _currentAddressController.text = userAddressResponse['current_address'] ?? '';
            _selectedAddress = userAddressResponse['current_address'];
          });
        }
      }

      final servicesOfferedData = widget.businessData['services_offered'];
      final servicePricesData = widget.businessData['service_prices'];

      print('DEBUG ORDER: servicesOfferedData = $servicesOfferedData');
      print('DEBUG ORDER: servicePricesData = $servicePricesData');
      print('DEBUG ORDER: servicePricesData type = ${servicePricesData.runtimeType}');

      List<Map<String, dynamic>> tempPricelist = [];

      if (servicePricesData != null && servicePricesData is List && servicePricesData.isNotEmpty) {
        print('DEBUG ORDER: Processing servicePricesData as List format');
        for (var item in servicePricesData) {
          if (item is Map<String, dynamic>) {
            String serviceName = item['service'] ?? item['service_name'] ?? '';
            String priceStr = '';

            if (item['price'] != null) {
              double price = double.tryParse(item['price'].toString()) ?? 0.0;
              priceStr = price.toStringAsFixed(2);
            } else {
              priceStr = '0.00';
            }

            if (serviceName.isNotEmpty) {
              tempPricelist.add({
                'service_name': serviceName,
                'price': priceStr,
                'description': _getServiceDescription(serviceName),
              });
            }
          }
        }
      } else if (servicePricesData != null && servicePricesData is Map<String, dynamic>) {
        print('DEBUG ORDER: Processing servicePricesData as Map format');
        servicesOfferedData?.forEach((service) {
          if (service is String) {
            final price = servicePricesData[service]?.toDouble() ?? 0.0;
            tempPricelist.add({
              'service_name': service,
              'price': price.toStringAsFixed(2),
              'description': _getServiceDescription(service),
            });
          }
        });
      } else if (servicesOfferedData is List) {
        print('DEBUG ORDER: No service_prices found, using services_offered = $servicesOfferedData');
        for (var serviceName in servicesOfferedData) {
          if (serviceName is String) {
            String defaultPrice = _getDefaultPrice(serviceName);
            String description = _getServiceDescription(serviceName);
            tempPricelist.add({
              'service_name': serviceName,
              'price': defaultPrice,
              'description': description,
            });
          }
        }
      }

      setState(() {
        _pricelist = tempPricelist;
        _isLoading = false;
      });
      print('DEBUG ORDER: Final _pricelist = $_pricelist');
    } catch (e) {
      print('DEBUG ORDER: Error loading business data from widget.businessData: $e');
      setState(() {
        _pricelist = [];
        _isLoading = false;
      });
    }
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'Wash & Fold':
        return 'Complete washing and folding service';
      case 'Ironing':
        return 'Professional ironing service';
      case 'Deliver':
        return 'Pickup and delivery service';
      case 'Dry Cleaning':
        return 'Professional dry cleaning';
      case 'Pressing':
        return 'Professional pressing service';
      default:
        return 'Professional laundry service';
    }
  }

  String _getDefaultPrice(String service) {
    switch (service.toLowerCase()) {
      case 'wash & fold':
        return '50.00';
      case 'ironing':
        return '30.00';
      case 'deliver':
      case 'delivery':
        return '20.00';
      case 'dry cleaning':
      case 'dry clean':
        return '80.00';
      case 'pressing':
        return '25.00';
      case 'pick up':
        return '15.00';
      case 'drop off':
        return '10.00';
      case 'self service':
        return '40.00';
      default:
        return '45.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
        backgroundColor: const Color(0xFF5A35E3),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.businessData['business_name'] ?? 'Business Name',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.businessData['business_address'] ??
                          'Business Address',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildAddressSection(),
                    const SizedBox(height: 16),
                    const Text(
                      'Place your Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildServicesSection(),
                    const SizedBox(height: 16),
                    _buildScheduleSection(),
                    const SizedBox(height: 16),
                    _buildInstructionsSection(),
                    const SizedBox(height: 16),
                    _buildTermsAndConditionsSection(),
                    const SizedBox(height: 32),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup & Drop-off Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final LatLng? selectedLocation = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickDropMapScreen(
                  initialLatitude: _latitude ?? 0.0,
                  initialLongitude: _longitude ?? 0.0,
                ),
              ),
            );
            if (selectedLocation != null) {
              setState(() {
                _latitude = selectedLocation.latitude;
                _longitude = selectedLocation.longitude;
                _latitudeController.text = _latitude.toString();
                _longitudeController.text = _longitude.toString();
              });
              _loadAddresses(); // Refresh data after returning from map screen
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF5A35E3),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_fullNameController.text}  (+63) ${_phoneNumberController.text}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0), // Adjust padding to align with the text above
                  child: Text(
                    _currentAddressController.text.isEmpty ? 'Add your Address here' : _currentAddressController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildServicesSection() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceSelectionScreen(
              selectedServices: _selectedServices,
              pricelist: _pricelist,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _selectedServices = Map<String, int>.from(result);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5A35E3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_laundry_service,
                color: Color(0xFF5A35E3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedServices.isEmpty 
                        ? 'Select services'
                        : '${_selectedServices.length} service(s) selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String? _selectedPickupTime;
  String? _selectedDropoffTime;
  DateTime? _selectedPickupDate;
  DateTime? _selectedDropoffDate;

  Widget _buildScheduleSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleSelectionScreen(
              selectedSchedule: _selectedSchedule,
              availablePickupTimeSlots: widget.availablePickupTimeSlots,
              availableDropoffTimeSlots: widget.availableDropoffTimeSlots,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _selectedSchedule = Map<String, String>.from(result);
            if (result['pickup'] != null) {
              _selectedPickupTime = result['pickup'] as String;
            }
            if (result['dropoff'] != null) {
              _selectedDropoffTime = result['dropoff'] as String;
            }
            if (result['pickupDate'] != null) {
              _selectedPickupDate = DateTime.parse(result['pickupDate']);
            }
            if (result['dropoffDate'] != null) {
              _selectedDropoffDate = DateTime.parse(result['dropoffDate']);
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5A35E3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF5A35E3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pick-Up & Drop-Off Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedSchedule == null 
                        ? 'Select schedule'
                        : 'Schedule selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A35E3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF5A35E3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Specific Instructions - Optional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  size: 20,
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Add any special instructions...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF5A35E3)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _specialInstructions = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue = _selectedAddress != null && 
                            _selectedServices.isNotEmpty && 
                            _selectedSchedule != null &&
                            _latitude != null && 
                            _longitude != null &&
                            (_selectedSchedule != null && (_selectedSchedule!.containsKey('pickup') || _selectedSchedule!.containsKey('dropoff')));
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canContinue ? _continueToConfirmation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A35E3),
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsSection() {
    final String termsAndConditions = _businessProfile?['terms_and_conditions'] ?? 'No terms and conditions provided.';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isTermsExpanded = !_isTermsExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A35E3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFF5A35E3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  _isTermsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  size: 20,
                ),
              ],
            ),
            if (_isTermsExpanded) ...[
              const SizedBox(height: 16),
              Text(
                termsAndConditions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _continueToConfirmation() {
    if (_currentAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address.')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service.')),
      );
      return;
    }

    if (_selectedSchedule == null || _selectedSchedule!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pick-up and drop-off schedule.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          businessData: {
            ...widget.businessData,
            'first_name': _firstName,
            'last_name': _lastName,
            'phone_number': _phoneNumber,
            'latitude': _latitude,
            'longitude': _longitude,
          },
          address: _currentAddressController.text,
          services: _selectedServices,
          schedule: _selectedSchedule!,
          laundryShopName: widget.businessData['business_name'],
          firstName: _firstName,
          lastName: _lastName,
          phoneNumber: _phoneNumber,
          pickupDate: _selectedPickupDate,
          dropoffDate: _selectedDropoffDate,
          pickupTime: _selectedPickupTime,
          dropoffTime: _selectedDropoffTime,
          specialInstructions: _specialInstructions,
        ),
      ),
    );
  }
}