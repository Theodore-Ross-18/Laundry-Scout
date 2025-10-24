import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laundry_scout/screens/home/Owner/owner_order_details.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending_orders';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('business_id', user.id)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> ordersWithUserDetails = [];
      for (var order in response) {
        final userId = order['user_id'];
        if (userId != null) {
          final userProfileResponse = await Supabase.instance.client
              .from('user_profiles')
              .select('first_name, last_name')
              .eq('id', userId)
              .single();
          order['user_profiles'] = userProfileResponse; 
        }
        ordersWithUserDetails.add(order);
      }

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(ordersWithUserDetails);
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

  Future<void> _setOrderAsComplete(String orderId) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', orderId);
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'pending_orders') {
      return _orders.where((order) =>
          order['status'] == 'pending' || order['status'] == 'in_progress').toList();
    } else if (_selectedFilter == 'past_orders') {
      return _orders.where((order) =>
          order['status'] == 'completed' || order['status'] == 'cancelled').toList();
    }
    return [];
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Orders', style: TextStyle(color: Color(0xFF5A35E3))),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('pending_orders', 'Pending Orders'),
                const SizedBox(width: 8),
                _buildFilterChip('past_orders', 'Past Orders'),
              ],
            ),
          ),
      
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders found',
                          style: TextStyle(fontSize: 16, color: Color(0xFF5A35E3)),
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
          color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[200],
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
    final customerFirstName = order['user_profiles']?['first_name'] ?? '';
    final customerLastName = order['user_profiles']?['last_name'] ?? '';
    final customerName = '$customerFirstName $customerLastName'.trim();
    final orderNumber = order['order_number'] ?? '';
    final status = order['status'] ?? 'pending';
    final createdAt = DateTime.parse(order['created_at']);

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
              children: [
                SvgPicture.asset('lib/assets/icons/laundry-machine.svg', width: 24, height: 24, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order ID : #$orderNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
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
              customerName,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${order['service_type'] ?? ''}',
              style: const TextStyle(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ordered at ${DateFormat('h:mm a, MMMM dd, yyyy').format(createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status == 'pending' || status == 'in_progress')
                  TextButton(
                    onPressed: () => _setOrderAsComplete(order['id']),
                    child: const Text('Accept', style: TextStyle(color: Color(0xFF5A35E3))),
                  ),
                if (status == 'pending' || status == 'in_progress')
                  TextButton(
                    onPressed: () {
                      _showCancelOrderDialog(context, order['id']);
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerOrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  child: const Text('View', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order', style: TextStyle(color: Colors.black)),
          content: const Text('Are you sure you want to cancel this order?', style: TextStyle(color: Colors.black)),
          actions: <Widget>[
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelOrder(orderId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}