import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Test method to verify notifications table exists and works
  /// Prevents spam by checking if test was already done for this user
  Future<void> testNotificationCreation() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for notification test');
        return;
      }

      print('🔍 Testing notifications table with user ID: ${user.id}');
      
      // Check if test notification already exists for this user
      final existingTest = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('type', 'system')
          .eq('title', 'Test Notification')
          .maybeSingle();
      
      if (existingTest != null) {
        print('✅ Test notification already exists for this user, skipping spam');
        return;
      }
      
      // First, try to read from the table to see if it exists
      await Supabase.instance.client
          .from('notifications')
          .select('*')
          .limit(1);
      
      print('✅ Notifications table exists and is readable');
      
      // Now try to insert a test notification
      await Supabase.instance.client.from('notifications').insert({
        'user_id': user.id,
        'title': 'Test Notification',
        'message': 'This is a test notification to verify the system works',
        'type': 'system',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {'test': true},
      });

      print('✅ Test notification created successfully');
    } catch (e) {
      print('❌ Test notification failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        print('❌ The notifications table does not exist in the database!');
      }
    }
  }

  /// Creates a notification when a new message is received
  Future<void> createMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String messageContent,
    required String businessId,
  }) async {
    try {
      // Don't create notification if the receiver is the sender
      if (receiverId == senderId) return;

      // Truncate message content for notification preview
      String notificationMessage = messageContent.length > 50 
          ? '${messageContent.substring(0, 50)}...'
          : messageContent;

      await Supabase.instance.client.from('notifications').insert({
        'user_id': receiverId,
        'title': 'New Message from $senderName',
        'message': notificationMessage,
        'type': 'message',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {
          'sender_id': senderId,
          'business_id': businessId,
          'message_preview': notificationMessage,
        },
      });

      print('✅ Message notification created for user: $receiverId');
    } catch (e) {
      print('❌ Failed to create message notification: $e');
    }
  }

  /// Creates a notification for business owners when they receive a message
  Future<void> createBusinessMessageNotification({
    required String businessOwnerId,
    required String customerName,
    required String messageContent,
    required String customerId,
  }) async {
    try {
      // Don't create notification if the business owner is the sender
      if (businessOwnerId == customerId) return;

      // Truncate message content for notification preview
      String notificationMessage = messageContent.length > 50 
          ? '${messageContent.substring(0, 50)}...'
          : messageContent;

      await Supabase.instance.client.from('notifications').insert({
        'user_id': businessOwnerId,
        'title': 'New Message from Customer',
        'message': '$customerName: $notificationMessage',
        'type': 'message',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {
          'customer_id': customerId,
          'customer_name': customerName,
          'message_preview': notificationMessage,
        },
      });

      print('✅ Business message notification created for owner: $businessOwnerId');
    } catch (e) {
      print('❌ Failed to create business message notification: $e');
    }
  }

  /// Gets user profile information for notification purposes
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      print('🔍 Fetching user profile for ID: $userId');
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('first_name, last_name, email, username')
          .eq('id', userId)
          .single();
      
      // Construct full name from first_name and last_name
      final firstName = response['first_name'] ?? '';
      final lastName = response['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      
      // Create a better fallback system
      String displayName;
      if (fullName.isNotEmpty) {
        displayName = fullName;
      } else if (response['username'] != null && response['username'].toString().isNotEmpty) {
        displayName = response['username'];
      } else if (response['email'] != null && response['email'].toString().isNotEmpty) {
        // Use the part before @ in email as fallback
        final email = response['email'].toString();
        displayName = email.split('@').first;
      } else {
        displayName = 'User${userId.substring(0, 8)}';
      }
      
      // Add full_name to the response for consistency
      response['full_name'] = displayName;
      
      print('✅ User profile found: $response');
      return response;
    } catch (e) {
      print('❌ Failed to get user profile for $userId: $e');
      return null;
    }
  }

  /// Gets business profile information for notification purposes
  Future<Map<String, dynamic>?> _getBusinessProfile(String businessId) async {
    try {
      print('🔍 Fetching business profile for ID: $businessId');
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('business_name, id, owner_first_name, owner_last_name, username, email')
          .eq('id', businessId)
          .single();
      print('✅ Business profile found: $response');
      return response;
    } catch (e) {
      print('❌ Failed to get business profile for $businessId: $e');
      // Let's also try to check if there are any business profiles at all
      try {
        final allBusinesses = await Supabase.instance.client
            .from('business_profiles')
            .select('id, business_name, owner_id')
            .limit(5);
        print('📋 Available business profiles: $allBusinesses');
      } catch (listError) {
        print('❌ Could not list business profiles: $listError');
      }
      return null;
    }
  }

  /// Creates appropriate notifications based on message context
  Future<void> handleMessageNotification({
    required String senderId,
    required String receiverId,
    required String businessId,
    required String messageContent,
  }) async {
    try {
      print('🔔 Creating notification: sender=$senderId, receiver=$receiverId, business=$businessId');
      
      // Get sender profile - this should always work for any user
      final senderProfile = await _getUserProfile(senderId);
      final senderName = senderProfile?['full_name'] ?? senderProfile?['username'] ?? 
          (senderProfile?['email']?.toString().split('@').first) ?? 
          'User${senderId.substring(0, 8)}';
      print('👤 Sender profile: $senderProfile, name: $senderName');

      // Get business profile - this might fail if businessId doesn't exist
      final businessProfile = await _getBusinessProfile(businessId);
      final businessOwnerId = businessProfile?['id']; // Changed from 'owner_id' to 'id'
      final businessName = businessProfile?['business_name'] ?? 'Business';
      print('🏢 Business profile: $businessProfile, owner: $businessOwnerId, name: $businessName');

      // If we couldn't get business profile, treat as regular user message
      if (businessProfile == null || businessOwnerId == null) {
        print('⚠️ No business profile found, treating as regular user message');
        await createMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: senderName,
          messageContent: messageContent,
          businessId: businessId,
        );
        return;
      }

      // Determine notification type based on sender and receiver
      if (senderId == businessOwnerId) {
        // Business owner is sending to customer
        print('📤 Laundry Shop Owner sending to customer, business name: $businessName');
        await createMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: businessName,  // This should use business name
          messageContent: messageContent,
          businessId: businessId,
        );
      } else if (receiverId == businessOwnerId) {
        // Customer is sending to business owner
        print('📥 Customer sending to Laundry Shop Owner');
        await createBusinessMessageNotification(
          businessOwnerId: businessOwnerId,
          customerName: senderName,  // This correctly uses customer name
          messageContent: messageContent,
          customerId: senderId,
        );
      } else {
        // Regular user-to-user message
        print('💬 Regular user-to-user message');
        await createMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: senderName,
          messageContent: messageContent,
          businessId: businessId,
        );
      }
    } catch (e) {
      print('❌ Failed to handle message notification: $e');
    }
  }

  /// Creates notifications for all users when a new promo is posted
  Future<void> createPromoNotification({
    required String businessId,
    required String promoTitle,
    required String promoDescription,
    String? promoImageUrl,
  }) async {
    try {
      print('🔔 Creating promo notifications for business: $businessId');
      
      // Get business profile
      final businessProfile = await _getBusinessProfile(businessId);
      final businessName = businessProfile?['business_name'] ?? 'A laundry shop';
      
      // Get all users except the business owner
      final usersResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .not('id', 'eq', businessId); // Don't notify the business owner
      
      print('📢 Found ${usersResponse.length} users to notify about promo');
      
      // Create notifications for all users
      final notifications = usersResponse.map((user) => {
        'user_id': user['id'],
        'title': '🎉 New Promo from $businessName!',
        'message': promoDescription.isNotEmpty ? promoDescription : 'Check out our latest promotion',
        'type': 'promo',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {
          'business_id': businessId,
          'business_name': businessName,
          'promo_title': promoTitle,
          'promo_image_url': promoImageUrl,
          'promo_type': 'new_promo',
        },
      }).toList();
      
      // Batch insert notifications
      if (notifications.isNotEmpty) {
        await Supabase.instance.client
            .from('notifications')
            .insert(notifications);
        
        print('✅ Successfully created ${notifications.length} promo notifications');
      }
    } catch (e) {
      print('❌ Failed to create promo notifications: $e');
    }
  }
}