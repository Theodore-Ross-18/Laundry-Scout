import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        'metadata': {
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
        'metadata': {
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
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Failed to get user profile: $e');
      return null;
    }
  }

  /// Gets business profile information for notification purposes
  Future<Map<String, dynamic>?> _getBusinessProfile(String businessId) async {
    try {
      final response = await Supabase.instance.client
          .from('businesses')
          .select('business_name, owner_id')
          .eq('id', businessId)
          .single();
      return response;
    } catch (e) {
      print('Failed to get business profile: $e');
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
      // Get sender profile
      final senderProfile = await _getUserProfile(senderId);
      final senderName = senderProfile?['full_name'] ?? 'Unknown User';

      // Get business profile
      final businessProfile = await _getBusinessProfile(businessId);
      final businessOwnerId = businessProfile?['owner_id'];
      final businessName = businessProfile?['business_name'] ?? 'Business';

      // Determine notification type based on sender and receiver
      if (senderId == businessOwnerId) {
        // Business owner is sending to customer
        await createMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: businessName,
          messageContent: messageContent,
          businessId: businessId,
        );
      } else if (receiverId == businessOwnerId) {
        // Customer is sending to business owner
        await createBusinessMessageNotification(
          businessOwnerId: businessOwnerId,
          customerName: senderName,
          messageContent: messageContent,
          customerId: senderId,
        );
      } else {
        // Regular user-to-user message
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
}