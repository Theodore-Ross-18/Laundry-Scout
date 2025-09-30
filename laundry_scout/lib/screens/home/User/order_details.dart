import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order['order_number']}'),
            Text('Customer Name: ${order['customer_name'] ?? 'N/A'}'),
            Text('Type of Service: ${order['type_of_service'] ?? 'N/A'}'),
            Text('Delivery Address: ${order['delivery_address'] ?? 'N/A'}'),
            Text('Paid via: ${order['payment_method'] ?? 'N/A'}'),
            Text('Estimated Bill: ₱${order['total_amount'] ?? '0.00'}'),
            // Add more details as needed based on the image
          ],
        ),
      ),
    );
  }
}