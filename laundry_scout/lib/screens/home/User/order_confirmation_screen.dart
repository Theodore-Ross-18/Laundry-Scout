import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:laundry_scout/widgets/static_map_snippet.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final String address;
  final Map<String, int> services;
  final Map<String, String> schedule;
  final String specialInstructions;
  final String termsAndConditions; 
  final double? latitude; 
  final double? longitude; 
  final String? firstName; 
  final String? lastName; 
  final String? laundryShopName; 
  final String? phoneNumber;

  const OrderConfirmationScreen({
    super.key,
    required this.businessData,
    required this.address,
    required this.services,
    required this.schedule,
    required this.specialInstructions,
    required this.termsAndConditions, 
    this.latitude, 
    this.longitude, 
    this.firstName, 
    this.lastName, 
    this.laundryShopName, 
    this.phoneNumber,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isPlacingOrder = false;
  bool _isTermsExpanded = false; 
  Map<String, dynamic>? _fullBusinessData; 

  Map<String, double> _servicePrices = {}; 

  @override
  void initState() {
    super.initState();
    _loadBusinessDataAndPrices();
  }

  Future<void> _loadBusinessDataAndPrices() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('service_prices')
          .eq('id', widget.businessData['id'])
          .single();

      _fullBusinessData = response;

      if (_fullBusinessData != null && _fullBusinessData!['service_prices'] != null) {
        final servicePricesData = _fullBusinessData!['service_prices'];
        if (servicePricesData is List) {
          for (var item in servicePricesData) {
            if (item is Map<String, dynamic>) {
              String serviceName = item['service'] ?? item['service_name'] ?? '';
              double price = double.tryParse(item['price'].toString()) ?? 0.0;
              if (serviceName.isNotEmpty) {
                _servicePrices[serviceName] = price;
              }
            }
          }
        } else if (servicePricesData is Map<String, dynamic>) {
          servicePricesData.forEach((serviceName, price) {
            _servicePrices[serviceName] = double.tryParse(price.toString()) ?? 0.0;
          });
        }
      }
      setState(() {}); 
    } catch (e) {
      print('Error loading business data and prices: $e');
    }
  }

  double get _subtotal {
    return widget.services.entries.fold(0.0, (sum, entry) {
      final serviceName = entry.key;
      final quantity = entry.value;
      return sum + ((_servicePrices[serviceName] ?? 0.0) * quantity);
    });
  }

  double get _total => _subtotal;

  String _generateOrderId() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    return 'PFFAS$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _generateOrderId();
    final pickupDate = DateTime.now().add(const Duration(days: 1));
    final dropoffDate = pickupDate.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A35E3),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                          
                            Container(
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
                                      const Text(
                                        'Order ID: ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        orderId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5A35E3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.schedule['pickup'] != null && widget.schedule['dropoff'] == null
                                                  ? 'Pickup only'
                                                  : 'Pickup at',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${DateFormat('MMM dd, yyyy').format(pickupDate)} | ${widget.schedule['pickup'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.schedule['dropoff'] != null && widget.schedule['pickup'] == null
                                                  ? 'Drop off only'
                                                  : 'Drop off',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${DateFormat('MMM dd, yyyy').format(dropoffDate)} | ${widget.schedule['dropoff'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Pickup & Drop-off Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF5A35E3),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.firstName ?? ''} ${widget.lastName ?? ''} (+63) ${widget.phoneNumber ?? ''}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.address,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (widget.latitude != null && widget.longitude != null) ...[
                              StaticMapSnippet(
                                latitude: widget.latitude!,
                                longitude: widget.longitude!,
                              ),
                              const SizedBox(height: 24),
                            ],
                          
                            const Text(
                              'Ordered Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  ...widget.services.entries.map((entry) {
                                    final serviceName = entry.key;
                                    final quantity = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$serviceName ($quantity kg)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '₱${(_servicePrices[serviceName] ?? 0.0) * quantity}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total (Estimate)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '₱${_total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildTermsAndConditionsSection(),

                            const SizedBox(height: 24),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Continue',
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
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final orderId = _generateOrderId();

      final String businessId = widget.businessData['id'];

      final String userId = supabase.auth.currentUser!.id;

      await supabase.from('orders').insert({
        'order_number': orderId,
        'user_id': userId,
        'business_id': businessId,
        'customer_name': '${widget.firstName ?? ''} ${widget.lastName ?? ''}',
        'laundry_shop_name': widget.laundryShopName,
        'pickup_address': widget.address,
        'delivery_address': widget.address, 
        'items': widget.services, 
        'pickup_schedule': widget.schedule['pickup'], 
        'dropoff_schedule': widget.schedule['dropoff'], 
        'special_instructions': widget.specialInstructions,
        'total_amount': _total,
        'status': 'pending',
        if (widget.latitude != null) 'latitude': widget.latitude,
        if (widget.longitude != null) 'longitude': widget.longitude,
        if (widget.phoneNumber != null) 'mobile_number': widget.phoneNumber,

      });

      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  Widget _buildTermsAndConditionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            trailing: Icon(
              _isTermsExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF5A35E3),
            ),
            onTap: () {
              setState(() {
                _isTermsExpanded = !_isTermsExpanded;
              });
            },
          ),
          if (_isTermsExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.termsAndConditions.isEmpty
                    ? 'No terms and conditions provided by the business.'
                    : widget.termsAndConditions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}