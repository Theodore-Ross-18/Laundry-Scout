import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connection_service.dart';
import 'notification_service.dart';

class QueuedMessage {
  final String id;
  final String content;
  final String receiverId;
  final String businessId;
  final DateTime timestamp;
  int retryCount;
  bool isCompressed;
  bool isSent;
  String? tempId; // For optimistic updates
  String? imageUrl; // URL for image messages
  bool isImage; // Whether this message contains an image

  QueuedMessage({
    required this.id,
    required this.content,
    required this.receiverId,
    required this.businessId,
    required this.timestamp,
    this.retryCount = 0,
    this.isCompressed = false,
    this.isSent = false,
    this.tempId,
    this.imageUrl,
    this.isImage = false,
  });
}

class MessageQueueService {
  static final MessageQueueService _instance = MessageQueueService._internal();
  factory MessageQueueService() => _instance;
  MessageQueueService._internal();

  final List<QueuedMessage> _messageQueue = [];
  final ConnectionService _connectionService = ConnectionService();
  final NotificationService _notificationService = NotificationService();
  final StreamController<QueuedMessage> _sentMessageController = StreamController.broadcast();
  Timer? _processingTimer;
  bool _isProcessing = false;

  Stream<QueuedMessage> get sentMessageStream => _sentMessageController.stream;

  void startQueue() {
    // More aggressive processing for better performance
    _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processQueue();
    });
  }

  void stopQueue() {
    _processingTimer?.cancel();
  }

  String queueMessage({
    required String content,
    required String receiverId,
    required String businessId,
    String? imageUrl,
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final isImage = imageUrl != null;
    final message = QueuedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _shouldCompress(content) ? _compressMessage(content) : content,
      receiverId: receiverId,
      businessId: businessId,
      timestamp: DateTime.now(),
      isCompressed: _shouldCompress(content),
      tempId: tempId,
      imageUrl: imageUrl,
      isImage: isImage,
    );

    _messageQueue.add(message);
    return tempId; // Return temp ID for optimistic updates
  }

  String queueImageMessage({
    required String imageUrl,
    required String receiverId,
    required String businessId,
    String? caption,
  }) {
    return queueMessage(
      content: caption ?? '',
      receiverId: receiverId,
      businessId: businessId,
      imageUrl: imageUrl,
    );
  }

  bool _shouldCompress(String content) {
    final quality = _connectionService.currentQuality;
    return content.length > 100 && 
           (quality == ConnectionQuality.poor || quality == ConnectionQuality.fair);
  }

  String _compressMessage(String content) {
    final bytes = utf8.encode(content);
    return base64Encode(bytes);
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _messageQueue.isEmpty) return;
    
    _isProcessing = true;
    final quality = _connectionService.currentQuality;
    
    try {
      switch (quality) {
        case ConnectionQuality.excellent:
          await _processBatch(10); // Aggressive batching for excellent connection
          break;
        case ConnectionQuality.good:
          await _processBatch(5);
          break;
        case ConnectionQuality.fair:
          await _processBatch(2);
          break;
        case ConnectionQuality.poor:
          await _processBatch(1);
          break;
        case ConnectionQuality.offline:
          // Don't process when offline
          break;
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processBatch(int batchSize) async {
    final batch = _messageQueue.where((msg) => !msg.isSent).take(batchSize).toList();
    
    // Process messages concurrently for better performance
    final futures = batch.map((message) => _sendMessage(message)).toList();
    await Future.wait(futures, eagerError: false);
  }

  Future<void> _sendMessage(QueuedMessage message) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final messageData = {
        'sender_id': user.id,
        'receiver_id': message.receiverId,
        'business_id': message.businessId,
        'content': message.content, // Content is non-nullable
        'is_compressed': message.isCompressed,
        'created_at': message.timestamp.toIso8601String(),
        'message_type': message.isImage ? 'image' : 'text', // Explicitly set message_type
        'is_image': message.isImage, // Explicitly set is_image field
      };

      // Add image URL if this is an image message
      final imageUrl = message.imageUrl;
      if (message.isImage && imageUrl != null) {
        messageData['image_url'] = imageUrl;
      }

      print('DEBUG: messageData before insert: $messageData'); // Added debug print

      await Supabase.instance.client.from('messages').insert(messageData);

      // Update conversation timestamp efficiently
      await _updateConversationTimestamp(message, user.id);

      // Create notification for the message recipient
      await _notificationService.handleMessageNotification(
        senderId: user.id,
        receiverId: message.receiverId,
        businessId: message.businessId,
        messageContent: message.isImage ? '📷 Image' : message.content,
      );

      message.isSent = true;
      _sentMessageController.add(message);
      _messageQueue.remove(message);
      
    } catch (e) {
      message.retryCount++;
      
      if (message.retryCount >= 5) {
        _messageQueue.remove(message);
        print('❌ Message failed after 5 retries: ${message.content}');
      } else {
        // Exponential backoff
        await Future.delayed(Duration(seconds: message.retryCount * 2));
      }
    }
  }

  Future<void> _updateConversationTimestamp(QueuedMessage message, String userId) async {
    try {
      print('🔍 Updating conversation timestamp:');
      print('   Current User ID: $userId');
      print('   Receiver ID: ${message.receiverId}');
      print('   Business ID: ${message.businessId}');
      print('   Auth User: ${Supabase.instance.client.auth.currentUser?.id}');
      
      // Determine the correct user_id and business_id for the conversation
      String conversationUserId;
      String conversationBusinessId = message.businessId;
      
      // If the current user is the business owner, the other party is the user
      // If the current user is a regular user, they are the user_id
      if (message.receiverId == message.businessId) {
        // Current user is sending to business, so current user is the customer
        conversationUserId = userId;
      } else {
        // Current user is the business responding to a customer
        conversationUserId = message.receiverId;
      }
  
      // First try to update existing conversation
      final updateResult = await Supabase.instance.client
          .from('conversations')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', conversationUserId)
          .eq('business_id', conversationBusinessId)
          .select();
  
      // If no rows were updated, the conversation doesn't exist, so create it
      if (updateResult.isEmpty) {
        await Supabase.instance.client
            .from('conversations')
            .insert({
              'user_id': conversationUserId,
              'business_id': conversationBusinessId,
              'last_message_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      print('⚠️ Failed to update conversation timestamp: $e');
    }
  }

  void dispose() {
    _processingTimer?.cancel();
    _sentMessageController.close();
  }
}