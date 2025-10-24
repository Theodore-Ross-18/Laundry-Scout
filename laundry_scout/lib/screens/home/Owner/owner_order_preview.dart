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
  final double? latitude; 
  final double? longitude; 
  final String? laundryShopName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String orderId;

  final DateTime? pickupDate;
  final DateTime? dropoffDate;
  final String? pickupTime;
  final String? dropoffTime;

  const OrderConfirmationScreen({
    super.key,
    required this.businessData,
    required this.address,
    required this.services,
    required this.schedule,
    required this.specialInstructions,
    this.latitude,
    this.longitude,
    this.laundryShopName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.pickupDate,
    this.dropoffDate,
    this.pickupTime,
    this.dropoffTime,
    required this.orderId,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Map<String, dynamic>? _fullBusinessData;
  Map<String, dynamic>? _orderData; // New state variable to store order details
  Map<String, double> _servicePrices = {}; 

  @override
  void initState() {
    super.initState();
    _loadBusinessDataAndPrices();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('order_number', widget.orderId)
          .single();
      setState(() {
        _orderData = response;
      });
      // print('Fetched order data: $_orderData'); // Removed this line
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  Future<void> _loadBusinessDataAndPrices() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('service_prices') // Removed delivery_fee
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
    if (_orderData == null || _orderData!['items'] == null) return 0.0;
    final Map<String, dynamic> itemsMap = _orderData!['items'];
    return itemsMap.entries.fold(0.0, (sum, entry) {
      final serviceName = entry.key;
      final quantity = (entry.value as num).toDouble(); // Cast to num then to double
      return sum + ((_servicePrices[serviceName] ?? 0.0) * quantity);
    });
  }

  double get _total => (_orderData!['total_amount'] as num).toDouble();

  double get _deliveryFeeAmount => _total - _subtotal;

  @override
  Widget build(BuildContext context) {
    // final orderId = _generateOrderId(); // Removed
    // final pickupDate = DateTime.now().add(const Duration(days: 1)); // Removed
    // final dropoffDate = pickupDate.add(const Duration(days: 1)); // Removed

    if (_orderData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF5A35E3),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final orderId = _orderData!['order_number'] ?? 'N/A';
    final pickupDate = _orderData!['pickup_date'] != null
        ? DateTime.parse(_orderData!['pickup_date'])
        : null;
    final dropoffDate = _orderData!['delivery_date'] != null
        ? DateTime.parse(_orderData!['delivery_date'])
        : null;

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
                                              pickupDate != null
                                                  ? '${DateFormat('MMM dd, yyyy').format(pickupDate)} | ${_orderData!['pickup_schedule'] ?? ''}'
                                                  : 'N/A',
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
                                              dropoffDate != null
                                                  ? '${DateFormat('MMM dd, yyyy').format(dropoffDate)} | ${_orderData!['dropoff_schedule'] ?? ''}'
                                                  : 'N/A',
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
                                          '${_orderData!['customer_name'] ?? ''} (+63) ${_orderData!['mobile_number'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _orderData!['pickup_address'] ?? 'N/A',
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
                            if (_orderData!['latitude'] != null && _orderData!['longitude'] != null) ...[
                              StaticMapSnippet(
                                latitude: _orderData!['latitude']!,
                                longitude: _orderData!['longitude']!,
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
                                  ...((_orderData!['items'] as Map<String, dynamic>).entries).map((entry) {
                                    final serviceName = entry.key;
                                    final quantity = (entry.value as num).toDouble(); // Cast to num then to double
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$serviceName (${quantity.toStringAsFixed(0)} kg)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '₱${((_servicePrices[serviceName] ?? 0.0) * quantity).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Delivery Fee',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '₱${_deliveryFeeAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
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
                                          color: Color(0xFF5A35E3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            
                            const SizedBox(height: 24),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Removed the "Continue" button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }
