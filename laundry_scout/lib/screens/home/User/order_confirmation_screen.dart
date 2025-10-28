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
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isPlacingOrder = false;
  bool _isTermsExpanded = false; 
  Map<String, dynamic>? _fullBusinessData; 

  Map<String, double> _servicePrices = {}; 
  double _deliveryFee = 0.0;
  double _appliedDiscount = 0.0;
  String? _promoTitle;

  @override
  void initState() {
    super.initState();
    _loadBusinessDataAndPrices();
  }

  Future<void> _loadBusinessDataAndPrices() async {
    try {
      final businessResponse = await Supabase.instance.client
          .from('business_profiles')
          .select('service_prices, delivery_fee')
          .eq('id', widget.businessData['id'])
          .single();

      _fullBusinessData = businessResponse;
      _deliveryFee = double.tryParse(_fullBusinessData!['delivery_fee'].toString()) ?? 0.0;

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

      // Fetch promo data
      final promoResponse = await Supabase.instance.client
          .from('promos')
          .select('promo_title, discount')
          .eq('business_id', widget.businessData['id'])
          .limit(1); // Get only one promo for now

      if (promoResponse.isNotEmpty) {
        final promo = promoResponse.first;
        _promoTitle = promo['promo_title'];
        final discountString = promo['discount'];

        if (discountString != null) {
          if (discountString.endsWith('%')) {
            final percentage = double.tryParse(discountString.replaceAll('%', '')) ?? 0.0;
            _appliedDiscount = _subtotal * (percentage / 100);
          } else {
            _appliedDiscount = double.tryParse(discountString) ?? 0.0;
          }
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

  double get _total => (_subtotal - _appliedDiscount) + _deliveryFee;

  String _generateOrderId() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    return 'PFFAS$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _generateOrderId();
    final pickupDate = widget.pickupDate ?? DateTime.now();
    final dropoffDate = widget.dropoffDate ?? pickupDate.add(const Duration(days: 1));

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
                                              widget.schedule['pickup']!.isNotEmpty && widget.schedule['dropoff']!.isEmpty
                                                  ? 'Pickup only'
                                                  : 'Pickup at',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (widget.schedule['pickup']!.isNotEmpty)
                                              Text(
                                                '${DateFormat('MMM dd, yyyy').format(pickupDate)} | ${widget.schedule['pickup']}',
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
                                              widget.schedule['dropoff']!.isNotEmpty && widget.schedule['pickup']!.isEmpty
                                                  ? 'Drop off only'
                                                  : 'Drop off',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (widget.schedule['dropoff']!.isNotEmpty)
                                              Text(
                                                '${DateFormat('MMM dd, yyyy').format(dropoffDate)} | ${widget.schedule['dropoff']}',
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
                                          '${widget.businessData['first_name'] ?? ''} ${widget.businessData['last_name'] ?? ''} (+63) ${widget.businessData['phone_number'] ?? ''}',
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
                            if (widget.businessData['latitude'] != null && widget.businessData['longitude'] != null) ...[
                              StaticMapSnippet(
                                latitude: widget.businessData['latitude']!,
                                longitude: widget.businessData['longitude']!,
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
                                  if (_appliedDiscount > 0 && _promoTitle != null) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Discount',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          '-₱${_appliedDiscount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
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
                                        '₱${_deliveryFee.toStringAsFixed(0)}',
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

  DateTime _parseDateTime(String dateString, String timeSlot) {
    final date = DateFormat('MMM dd, yyyy').parse(dateString);
    final timeParts = timeSlot.split(RegExp(r'[- ]')).where((s) => s.isNotEmpty).toList();
    String startTime = timeParts[0] + timeParts[1]; // e.g., "8:00AM"
    
    // Handle cases where the time format might be "8:00 AM" or "8 AM"
    if (timeParts.length > 2 && (timeParts[1].toLowerCase() == 'am' || timeParts[1].toLowerCase() == 'pm')) {
      startTime = timeParts[0] + timeParts[1];
    } else if (timeParts.length > 1 && (timeParts[0].contains(':') && (timeParts[1].toLowerCase() == 'am' || timeParts[1].toLowerCase() == 'pm'))) {
      startTime = timeParts[0] + timeParts[1];
    } else if (timeParts.length > 0 && timeParts[0].contains(':') && (timeParts.last.toLowerCase() == 'am' || timeParts.last.toLowerCase() == 'pm')) {
      startTime = timeParts[0] + timeParts.last;
    } else {
      // Fallback for unexpected formats, try to use the first part
      startTime = timeParts[0];
    }

    // Ensure AM/PM is correctly formatted for parsing
    if (!startTime.contains(RegExp(r'[APap][Mm]'))) {
      // Assume AM if not specified and hour is less than 12, otherwise PM
      if (int.tryParse(startTime.split(':')[0]) != null && int.parse(startTime.split(':')[0]) < 12) {
        startTime += 'AM';
      } else {
        startTime += 'PM';
      }
    }

    final time = DateFormat('h:mma').parse(startTime);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

      // Parse pickup and dropoff dates
      DateTime? parsedPickupDate;
      if (widget.schedule['pickup']!.isNotEmpty && widget.pickupDate != null) {
        parsedPickupDate = _parseDateTime(DateFormat('MMM dd, yyyy').format(widget.pickupDate!), widget.schedule['pickup']!);
      } else if (widget.schedule['pickup']!.isNotEmpty) {
        parsedPickupDate = _parseDateTime(DateFormat('MMM dd, yyyy').format(DateTime.now()), widget.schedule['pickup']!);
      }

      DateTime? parsedDropoffDate;
      if (widget.schedule['dropoff']!.isNotEmpty && widget.dropoffDate != null) {
        parsedDropoffDate = _parseDateTime(DateFormat('MMM dd, yyyy').format(widget.dropoffDate!), widget.schedule['dropoff']!);
      } else if (widget.schedule['dropoff']!.isNotEmpty) {
        parsedDropoffDate = _parseDateTime(DateFormat('MMM dd, yyyy').format(DateTime.now()), widget.schedule['dropoff']!);
      }

      await supabase.from('orders').insert({
        'order_number': orderId,
        'user_id': userId,
        'business_id': businessId,
        'customer_name': '${widget.firstName ?? ''} ${widget.lastName ?? ''}',
        'laundry_shop_name': widget.laundryShopName ?? widget.businessData['business_name'],
        'pickup_address': widget.address,
        'delivery_address': widget.address, 
        'items': widget.services, 
        'pickup_schedule': widget.schedule['pickup'], 
        'dropoff_schedule': widget.schedule['dropoff'], 
        'special_instructions': widget.specialInstructions,
        'total_amount': _total,
        'status': 'pending',
        'pickup_date': parsedPickupDate?.toIso8601String(), // Add parsed pickup date
        'delivery_date': parsedDropoffDate?.toIso8601String(), // Add parsed dropoff date
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
    final String termsAndConditions = widget.businessData['terms_and_conditions'] ?? 'No terms and conditions provided.';
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
                termsAndConditions.isEmpty
                    ? 'No terms and conditions provided by the business.'
                    : termsAndConditions,
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