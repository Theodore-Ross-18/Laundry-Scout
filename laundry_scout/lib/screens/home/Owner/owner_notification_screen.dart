import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:laundry_scout/screens/home/Owner/edit_profile_screen.dart'; // Add this line
import 'package:collection/collection.dart'; // Add this line

class OwnerNotificationScreen extends StatefulWidget {
  const OwnerNotificationScreen({super.key});

  @override
  State<OwnerNotificationScreen> createState() => _OwnerNotificationScreenState();
}

class _OwnerNotificationScreenState extends State<OwnerNotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  late RealtimeChannel _notificationsSubscription;
  final Map<String, String> _userNames = {}; // Cache for user names

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

      // After loading existing notifications, check for profile completeness
      await _checkAndAddProfileSetupNotification();

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
      case 'profile_setup': // New case for profile setup notification
        return Icons.person_add;
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
      case 'profile_setup': // New case for profile setup notification
        return Colors.purple;
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

  Future<void> _checkAndAddProfileSetupNotification() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: No authenticated user found.');
        return;
      }

      print('✅ [OWNER] _checkAndAddProfileSetupNotification: User ID: ${user.id}');

      // Fetch business profile data
      final businessProfileResponse = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', user.id)
          .single();

      print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Business Profile Response: $businessProfileResponse');

      final profileData = businessProfileResponse;
      print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Profile Data: $profileData');

      // Determine if profile is complete
      bool isProfileComplete = true;
      String missingField = '';

      if (profileData['business_name'] == null || profileData['business_name'].isEmpty) {
        isProfileComplete = false;
        missingField = 'Business Name';
        print('⚠️ [OWNER] Profile incomplete: Missing Business Name');
      } else if (profileData['email'] == null || profileData['email'].isEmpty) {
        isProfileComplete = false;
        missingField = 'Email';
        print('⚠️ [OWNER] Profile incomplete: Missing Email');
      } else if (profileData['business_phone_number'] == null || profileData['business_phone_number'].isEmpty) {
        isProfileComplete = false;
        missingField = 'Business Phone Number';
        print('⚠️ [OWNER] Profile incomplete: Missing Business Phone Number');
      } else if (profileData['about_business'] == null || profileData['about_business'].isEmpty) {
        isProfileComplete = false;
        missingField = 'About Business';
        print('⚠️ [OWNER] Profile incomplete: Missing About Business');
      } else if (profileData['services_offered'] == null || (profileData['services_offered'] as List).isEmpty) {
        isProfileComplete = false;
        missingField = 'Services Offered';
        print('⚠️ [OWNER] Profile incomplete: Missing Services Offered');
      } else if (profileData['service_prices'] == null || (profileData['service_prices'] as List).isEmpty) {
        isProfileComplete = false;
        missingField = 'Service Prices';
        print('⚠️ [OWNER] Profile incomplete: Missing Service Prices');
      }

      print('ℹ️ [OWNER] _checkAndAddProfileSetupNotification: Is Profile Complete: $isProfileComplete, Missing Field: $missingField');

      if (!mounted) return;

      if (!isProfileComplete) {
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Profile is INCOMPLETE. Checking for existing incomplete notification.');
        // Check if an 'profile_setup_incomplete' notification already exists (read or unread)
        final existingIncompleteNotification = _notifications.firstWhereOrNull(
            (n) => n['type'] == 'profile_setup' && n['status_type'] == 'incomplete');
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Existing incomplete notification: $existingIncompleteNotification');

        if (existingIncompleteNotification == null) {
          // Insert new 'profile_setup_incomplete' notification
          final newNotification = {
            'user_id': user.id,
            'type': 'profile_setup',
            'status_type': 'incomplete',
            'title': 'Complete Your Business Profile',
            'message': 'Your business profile is incomplete. Please complete it to unlock all features.',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          };
          await Supabase.instance.client.from('notifications').insert(newNotification);
          setState(() {
            _notifications.insert(0, newNotification);
          });
          print('✅ [OWNER] _checkAndAddProfileSetupNotification: Added new incomplete profile setup notification.');
        } else {
          print('ℹ️ [OWNER] _checkAndAddProfileSetupNotification: Incomplete profile setup notification already exists.');
        }
      } else {
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Profile is COMPLETE. Checking for existing notifications.');
        // Profile is complete
        // Mark any existing unread 'profile_setup_incomplete' notifications as read
        final incompleteNotificationsToMarkRead = _notifications.where(
            (n) => n['type'] == 'profile_setup' && n['status_type'] == 'incomplete' && n['is_read'] == false).toList();
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Incomplete notifications to mark as read: ${incompleteNotificationsToMarkRead.length}');

        for (var notification in incompleteNotificationsToMarkRead) {
          await Supabase.instance.client
              .from('notifications')
              .update({'is_read': true})
              .eq('id', notification['id']);
          print('✅ [OWNER] _checkAndAddProfileSetupNotification: Marked incomplete notification ${notification['id']} as read.');
        }

        // Check if a 'profile_setup_complete' notification already exists (read or unread)
        final existingCompleteNotification = _notifications.firstWhereOrNull(
            (n) => n['type'] == 'profile_setup' && n['status_type'] == 'complete');
        print('🔍 [OWNER] _checkAndAddProfileSetupNotification: Existing complete notification: $existingCompleteNotification');


        if (existingCompleteNotification == null) {
          // Insert new 'profile_setup_complete' notification
          final newNotification = {
            'user_id': user.id,
            'type': 'profile_setup',
            'status_type': 'complete',
            'title': 'Business Profile Complete!',
            'message': 'Your business profile is now complete. You can manage it anytime.',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          };
          await Supabase.instance.client.from('notifications').insert(newNotification);
          setState(() {
            _notifications.insert(0, newNotification);
          });
          print('✅ [OWNER] _checkAndAddProfileSetupNotification: Added new complete profile setup notification.');
        } else {
          print('ℹ️ [OWNER] _checkAndAddProfileSetupNotification: Complete profile setup notification already exists.');
        }
      }
    } catch (e) {
      print('❌ [OWNER] Error checking and adding profile setup notification: $e');
    }
  }

  String _getDisplayTitle(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'booking_request':
        return 'New Booking Request';
      case 'booking_accepted':
        return 'Booking Accepted';
      case 'booking_declined':
        return 'Booking Declined';
      case 'booking_completed':
        return 'Booking Completed';
      case 'profile_setup':
        if (notification['status_type'] == 'incomplete') {
          return 'Complete Your Business Profile';
        } else if (notification['status_type'] == 'complete') {
          return 'Business Profile Complete!';
        }
        return 'Profile Setup Notification';
      default:
        return 'New Notification';
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B61FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            const SizedBox(height: 20), // Added for spacing
            Image.asset(
              'lib/assets/lslogo.png',
              height: 40, // Adjust height as needed
              color: Colors.white,
            ),
            const SizedBox(height: 10), // Spacing between logo and text
            const Text(
              'Laundry Scout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10), // Spacing between text and button
            // Notifications section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mark_email_read, color: Colors.white),
                    onPressed: _markAllAsRead,
                    tooltip: 'Mark all as read',
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: Container(
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
                                    if (notification['type'] == 'profile_setup') {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const EditProfileScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}