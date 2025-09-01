import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connection_service.dart';

class QueuedMessage {
  final String id;
  final String content;
  final String receiverId;
  final String businessId;
  final DateTime timestamp;
  int retryCount;
  bool isCompressed;

  QueuedMessage({
    required this.id,
    required this.content,
    required this.receiverId,
    required this.businessId,
    required this.timestamp,
    this.retryCount = 0,
    this.isCompressed = false,
  });
}

class MessageQueueService {
  static final MessageQueueService _instance = MessageQueueService._internal();
  factory MessageQueueService() => _instance;
  MessageQueueService._internal();

  final List<QueuedMessage> _messageQueue = [];
  final ConnectionService _connectionService = ConnectionService();
  Timer? _processingTimer;
  bool _isProcessing = false;

  void startQueue() {
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processQueue();
    });
  }

  void stopQueue() {
    _processingTimer?.cancel();
  }

  void queueMessage({
    required String content,
    required String receiverId,
    required String businessId,
  }) {
    final message = QueuedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _shouldCompress(content) ? _compressMessage(content) : content,
      receiverId: receiverId,
      businessId: businessId,
      timestamp: DateTime.now(),
      isCompressed: _shouldCompress(content),
    );

    _messageQueue.add(message);
  }

  bool _shouldCompress(String content) {
    final quality = _connectionService.currentQuality;
    return content.length > 100 && 
           (quality == ConnectionQuality.poor || quality == ConnectionQuality.fair);
  }

  String _compressMessage(String content) {
    // Simple compression - in production, use gzip or similar
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
        case ConnectionQuality.good:
          await _processBatch(5); // Send up to 5 messages at once
          break;
        case ConnectionQuality.fair:
          await _processBatch(2); // Send up to 2 messages at once
          break;
        case ConnectionQuality.poor:
          await _processBatch(1); // Send one message at a time
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
    final batch = _messageQueue.take(batchSize).toList();
    final futures = <Future>[];

    for (final message in batch) {
      futures.add(_sendMessage(message));
    }

    await Future.wait(futures);
  }

  Future<void> _sendMessage(QueuedMessage message) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': message.receiverId,
        'business_id': message.businessId,
        'content': message.content,
        'is_compressed': message.isCompressed,
        'created_at': message.timestamp.toIso8601String(),
      });

      // Update conversation timestamp
      await Supabase.instance.client
          .from('conversations')
          .upsert({
            'user_id': user.id,
            'business_id': message.businessId,
            'last_message_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,business_id');

      _messageQueue.remove(message);
    } catch (e) {
      message.retryCount++;
      
      if (message.retryCount >= 3) {
        // Remove message after 3 failed attempts
        _messageQueue.remove(message);
        print('Message failed after 3 retries: ${message.content}');
      }
    }
  }
}