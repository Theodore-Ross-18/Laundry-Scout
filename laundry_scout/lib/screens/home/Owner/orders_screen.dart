import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get orders for this business owner
      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('business_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'all') return _orders;
    return _orders.where((order) => order['status'] == _selectedFilter).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Refresh orders
      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customerName = 'Customer'; // Simplified for now - can be enhanced later
    final orderNumber = order['order_number'] ?? 'N/A';
    final status = order['status'] ?? 'pending';
    final createdAt = DateTime.parse(order['created_at']);
    final totalAmount = order['total_amount']?.toDouble() ?? 0.0;

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color statusBgColor;
    switch (status) {
      case 'pending':
        statusBgColor = Colors.orange.withOpacity(0.15);
        break;
      case 'in_progress':
        statusBgColor = Colors.blue.withOpacity(0.15);
        break;
      case 'completed':
        statusBgColor = Colors.green.withOpacity(0.15);
        break;
      case 'cancelled':
        statusBgColor = Colors.red.withOpacity(0.15);
        break;
      default:
        statusBgColor = Colors.grey.withOpacity(0.15);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: $customerName',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ₱${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'in_progress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'in_progress') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus(order['id'], 'completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
            ],
            if (status == 'completed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdf = pw.Document();
                    pdf.addPage(
                      pw.Page(
                        build: (pw.Context context) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Order Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 16),
                              pw.Text('Order #: $orderNumber'),
                              pw.Text('Customer: $customerName'),
                              pw.Text('Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)}'),
                              pw.Text('Total: ₱${totalAmount.toStringAsFixed(2)}'),
                              pw.Text('Payment Method: ${order['payment_method'] ?? 'N/A'}'),
                              pw.Text('Payment Balance: ₱${order['payment_balance']?.toStringAsFixed(2) ?? '0.00'}'),
                            ],
                          );
                        },
                      ),
                    );
                    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Payment Method: ${order['payment_method'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment Balance: ₱${order['payment_balance']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}