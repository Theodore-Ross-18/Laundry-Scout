import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OwnerNotificationScreen extends StatefulWidget {
  const OwnerNotificationScreen({super.key});

  @override
  State<OwnerNotificationScreen> createState() => _OwnerNotificationScreenState();
}

class _OwnerNotificationScreenState extends State<OwnerNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  late RealtimeChannel _notificationsSubscription;
  Map<String, String> _userNames = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _notificationsSubscription.unsubscribe();
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

      final notifications = List<Map<String, dynamic>>.from(response);
      
      // Fetch user names for message notifications
      await _fetchUserNamesForNotifications(notifications);

      if (mounted) {
        setState(() {
          _notifications = notifications;
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

  Future<void> _fetchUserNamesForNotifications(List<Map<String, dynamic>> notifications) async {
    final senderIds = <String>{};
    
    print('🔍 [OWNER] Fetching user names for ${notifications.length} notifications');
    
    for (final notification in notifications) {
      print('📋 [OWNER] Notification: ${notification['type']}, data: ${notification['data']}');
      if (notification['type'] == 'message' && notification['data'] != null) {
        final data = notification['data'] as Map<String, dynamic>;
        final senderId = data['customer_id'] as String? ?? data['sender_id'] as String?;
        print('👤 [OWNER] Found sender ID: $senderId');
        print('👤 [OWNER] Data keys: ${data.keys.toList()}');
        if (senderId != null) {
          senderIds.add(senderId);
        }
      }
    }
    
    print('🔍 [OWNER] Total sender IDs to fetch: ${senderIds.length}');
    
    // Fetch user profiles for all sender IDs
    for (final senderId in senderIds) {
      if (!_userNames.containsKey(senderId)) {
        try {
          print('🔍 [OWNER] Fetching profile for sender: $senderId');
          final response = await Supabase.instance.client
              .from('user_profiles')
              .select('full_name')
              .eq('id', senderId)
              .single();
          final fullName = response['full_name'] ?? 'Unknown User';
          _userNames[senderId] = fullName;
          print('✅ [OWNER] Found user: $fullName for ID: $senderId');
        } catch (e) {
          print('❌ [OWNER] Failed to fetch user profile for $senderId: $e');
          _userNames[senderId] = 'Unknown User';
        }
      }
    }
    
    print('📝 [OWNER] Final user names cache: $_userNames');
  }

  String _getDisplayTitle(Map<String, dynamic> notification) {
    // Use the original title from the database since it already contains the correct sender name
    return notification['title'] ?? 'Notification';
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
  
    _notificationsSubscription = Supabase.instance.client
        .channel('owner_notifications_${user.id}')
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
      case 'order':
        return Icons.shopping_bag;
      case 'message':
        return Icons.message;
      case 'feedback':
        return Icons.star;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.green;
      case 'message':
        return Colors.blue;
      case 'feedback':
        return Colors.orange;
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
          'Notifications',
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
      ),
      body: Container(
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
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] ?? false;
                      
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
                            backgroundColor: _getNotificationColor(notification['type'] ?? 'general').withOpacity(0.1),
                            child: Icon(
                              _getNotificationIcon(notification['type'] ?? 'general'),
                              color: _getNotificationColor(notification['type'] ?? 'general'),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _getDisplayTitle(notification),
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16,
                            ),
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
    );
  }
}