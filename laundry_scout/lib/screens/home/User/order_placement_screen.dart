import 'package:flutter/material.dart';
import 'address_selection_screen.dart';
import 'service_selection_screen.dart';
import 'schedule_selection_screen.dart';
import 'order_confirmation_screen.dart';

class OrderPlacementScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const OrderPlacementScreen({super.key, required this.businessData});

  @override
  State<OrderPlacementScreen> createState() => _OrderPlacementScreenState();
}

class _OrderPlacementScreenState extends State<OrderPlacementScreen> {
  String? _selectedAddress;
  List<String> _selectedServices = [];
  Map<String, String>? _selectedSchedule;
  String _specialInstructions = '';
  bool _isExpanded = false;
  List<Map<String, dynamic>> _pricelist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F5ADC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laundry Scout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAddressSection(),
                            const SizedBox(height: 20),
                            _buildServicesSection(),
                            const SizedBox(height: 20),
                            _buildScheduleSection(),
                            const SizedBox(height: 20),
                            _buildInstructionsSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddressSelectionScreen(),
          ),
        );
        if (result != null) {
          setState(() {
            _selectedAddress = result;
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
                color: const Color(0xFF6F5ADC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.home,
                color: Color(0xFF6F5ADC),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddress ?? 'Your Current Location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBusinessData() async {
    try {
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
            _selectedServices = List<String>.from(result);
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
                color: const Color(0xFF6F5ADC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_laundry_service,
                color: Color(0xFF6F5ADC),
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

  Widget _buildScheduleSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleSelectionScreen(
              selectedSchedule: _selectedSchedule,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _selectedSchedule = Map<String, String>.from(result);
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
                color: const Color(0xFF6F5ADC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF6F5ADC),
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
                    color: const Color(0xFF6F5ADC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF6F5ADC),
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
                    borderSide: const BorderSide(color: Color(0xFF6F5ADC)),
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
                            _selectedSchedule != null;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canContinue ? _continueToConfirmation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6F5ADC),
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

  void _continueToConfirmation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          businessData: widget.businessData,
          address: _selectedAddress!,
          services: _selectedServices,
          schedule: _selectedSchedule!,
          specialInstructions: _specialInstructions,
        ),
      ),
    );
  }
}