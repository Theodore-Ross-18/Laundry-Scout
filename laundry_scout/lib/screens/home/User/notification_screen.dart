import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:laundry_scout/screens/home/User/order_details.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  late RealtimeChannel _notificationsSubscription;
  late TabController _tabController;

  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadOrders();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _notificationsSubscription.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _loadOrders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Now, for each order, fetch the user_profile data
      List<Map<String, dynamic>> ordersWithUserDetails = [];
      for (var order in response) {
        final userId = order['user_id'];
        if (userId != null) {
          final userProfileResponse = await Supabase.instance.client
              .from('user_profiles')
              .select('first_name, last_name')
              .eq('id', userId)
              .single();
          order['user_profiles'] = userProfileResponse; // Attach user profile to the order
        }
        ordersWithUserDetails.add(order);
      }

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(ordersWithUserDetails);
          _ordersLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _ordersLoading = false;
        });
      }
    }
  }

  Future<String> _getDisplayTitle(Map<String, dynamic> notification) async {
    String title = notification['title'] ?? 'Notification';
    
    // Check if title contains a User ID pattern and try to replace with business name
    if (title.contains('User') && title.contains('New Message from User')) {
      try {
        // Extract the sender ID from notification data
        final data = notification['data'] as Map<String, dynamic>?;
        final senderId = data?['sender_id'];
        final businessId = data?['business_id'];
        
        if (senderId != null && businessId != null) {
          // Try to get business information
          final businessResponse = await Supabase.instance.client
              .from('business_profiles')
              .select('business_name, owner_id')
              .eq('id', businessId)
              .maybeSingle();
          
          if (businessResponse != null && businessResponse['owner_id'] == senderId) {
            // This is a business owner, use business name
            final businessName = businessResponse['business_name'] ?? 'Business';
            return title.replaceAll(RegExp(r'User[a-zA-Z0-9-]+'), businessName);
          }
        }
        
        // If not a business owner, try to get user profile
        if (senderId != null) {
          final userResponse = await Supabase.instance.client
              .from('user_profiles')
              .select('first_name, last_name, username, email')
              .eq('id', senderId)
              .maybeSingle();
          
          if (userResponse != null) {
            String displayName = '';
            final firstName = userResponse['first_name'] ?? '';
            final lastName = userResponse['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            
            if (fullName.isNotEmpty) {
              displayName = fullName;
            } else if (userResponse['username'] != null && userResponse['username'].toString().isNotEmpty) {
              displayName = userResponse['username'];
            } else if (userResponse['email'] != null && userResponse['email'].toString().isNotEmpty) {
              displayName = userResponse['email'].toString().split('@').first;
            }
            
            if (displayName.isNotEmpty) {
              return title.replaceAll(RegExp(r'User[a-zA-Z0-9-]+'), displayName);
            }
          }
        }
      } catch (e) {
        print('Error improving notification title: $e');
      }
    }
    
    return title;
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _notificationsSubscription = Supabase.instance.client
        .channel('notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newNotification = payload.newRecord;
            if (mounted) {
              setState(() {
                _notifications.insert(0, newNotification);
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'promo':
        return Icons.local_offer;
      case 'order':
        return Icons.shopping_bag;
      case 'message':
        return Icons.message;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'promo':
        return Colors.orange;
      case 'order':
        return Colors.green;
      case 'message':
        return Colors.blue;
      case 'system':
        return Colors.grey;
      default:
        return const Color(0xFF7B61FF);
    }
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B61FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B61FF),
        elevation: 0,
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all as Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Orders'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isRead = notification['is_read'] ?? false;
                          final type = notification['type'] ?? 'general';
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getNotificationColor(type).withOpacity(0.1),
                                child: Icon(
                                  _getNotificationIcon(type),
                                  color: _getNotificationColor(type),
                                  size: 20,
                                ),
                              ),
                              title: FutureBuilder<String>(
                                future: _getDisplayTitle(notification),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? (notification['title'] ?? 'Notification'),
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(notification['created_at']),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7B61FF),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (!isRead) {
                                  _markAsRead(notification['id']);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: _ordersLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('lib/assets/icons/laundry-machine.svg', width: 24, height: 24, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Order ID : #$orderNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
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
            ),
            const SizedBox(height: 0),
            Text(
              '${order['service_type'] ?? ''}',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ordered at ${DateFormat('h:mm a, MMMM dd, yyyy').format(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                      child: const Text('View', style: TextStyle(color: Colors.black)),
                    ),
                    if (status == 'pending')
                      TextButton(
                        onPressed: () {
                          _showCancelOrderDialog(context, order['id']);
                        },
                        child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                      ),
                  ],
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
          title: const Text('Cancel Order'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
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
      _loadOrders(); // Refresh the orders list
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