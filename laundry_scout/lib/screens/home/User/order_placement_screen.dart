import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final businessId = widget.businessData['id'];
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('services_offered')
          .eq('id', businessId)
          .single();

      final servicesOffered = response['services_offered'];

      print('DEBUG ORDER: servicesOffered = $servicesOffered');
      print('DEBUG ORDER: servicesOffered type = ${servicesOffered.runtimeType}');
      print('DEBUG ORDER: servicesOffered is null? = ${servicesOffered == null}');

      setState(() {
        _pricelist = [];
        
        if (servicesOffered is List) {
          print('DEBUG ORDER: Processing as List format');
          // Handle JSONB array format with objects containing 'service' and 'price' fields
          for (var item in servicesOffered) {
            print('DEBUG ORDER: Processing item = $item');
            if (item is Map<String, dynamic>) {
              String priceStr = '';
              if (item['price'] != null) {
                // Ensure price is formatted as a string with 2 decimal places
                double price = double.tryParse(item['price'].toString()) ?? 0.0;
                priceStr = price.toStringAsFixed(2);
              } else {
                priceStr = '0.00';
              }
              
              _pricelist.add({
                'service_name': item['service'] ?? '',
                'price': priceStr,
              });
            }
          }
        } else if (servicesOffered is Map<String, dynamic>) {
          print('DEBUG ORDER: Processing as Map format');
          // Handle JSONB object format where keys are service names and values are prices
          servicesOffered.forEach((service, price) {
            String priceStr = '';
            if (price != null) {
              // Ensure price is formatted as a string with 2 decimal places
              double priceValue = double.tryParse(price.toString()) ?? 0.0;
              priceStr = priceValue.toStringAsFixed(2);
            } else {
              priceStr = '0.00';
            }
            
            _pricelist.add({
              'service_name': service,
              'price': priceStr,
            });
          });
        }
        
        print('DEBUG ORDER: Final _pricelist = $_pricelist');
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ORDER: Error loading business data: $e');
      setState(() {
        // Fallback to widget.businessData if Supabase fails
        final servicesOffered = widget.businessData['services_offered'] as List<dynamic>? ?? [];
        final servicePrices = widget.businessData['service_prices'];
        
        print('DEBUG ORDER FALLBACK: servicesOffered = $servicesOffered');
        print('DEBUG ORDER FALLBACK: servicePrices = $servicePrices');
        print('DEBUG ORDER FALLBACK: servicePrices type = ${servicePrices.runtimeType}');
        
        _pricelist = [];
        
        if (servicePrices is List) {
          print('DEBUG ORDER FALLBACK: Processing as List format');
          // Handle JSONB array format with objects containing 'service' and 'price' fields
          for (var item in servicePrices) {
            print('DEBUG ORDER FALLBACK: Processing item = $item');
            if (item is Map<String, dynamic>) {
              _pricelist.add({
                'service_name': item['service'] ?? '',
                'price': (item['price']?.toDouble() ?? 0.0).toStringAsFixed(2),
              });
            }
          }
        } else if (servicePrices is Map<String, dynamic>) {
          print('DEBUG ORDER FALLBACK: Processing as Map format');
          // Handle JSONB object format where keys are service names and values are prices
          for (String service in servicesOffered) {
            final price = servicePrices[service]?.toDouble() ?? 0.0;
            _pricelist.add({
              'service_name': service,
              'price': price.toStringAsFixed(2),
            });
          }
        }
        
        print('DEBUG ORDER FALLBACK: Final _pricelist = $_pricelist');
        _isLoading = false;
      });
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