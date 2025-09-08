import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connection_service.dart';

class RealtimeMessageService {
  static final RealtimeMessageService _instance = RealtimeMessageService._internal();
  factory RealtimeMessageService() => _instance;
  RealtimeMessageService._internal();

  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  final ConnectionService _connectionService = ConnectionService();
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  Timer? _cacheCleanupTimer;
  
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void initialize() {
    _connectionService.startMonitoring();
    _startCacheCleanup();
  }

  void dispose() {
    _activeChannels.values.forEach((channel) => channel.unsubscribe());
    _activeChannels.clear();
    _cacheCleanupTimer?.cancel();
    _messageController.close();
  }

  // Optimized channel subscription with connection-aware settings
  RealtimeChannel subscribeToConversation(String conversationId, {
    required Function(Map<String, dynamic>) onMessage,
    String? userId,
    String? businessId,
  }) {
    final channelKey = 'conversation_$conversationId';
    
    // Reuse existing channel if available
    if (_activeChannels.containsKey(channelKey)) {
      return _activeChannels[channelKey]!;
    }

    final channel = Supabase.instance.client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: _buildMessageFilter(userId, businessId),
          callback: (payload) {
            final message = payload.newRecord;
            _handleIncomingMessage(message, onMessage);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public', 
          table: 'messages',
          filter: _buildMessageFilter(userId, businessId),
          callback: (payload) {
            final message = payload.newRecord;
            _handleMessageUpdate(message, onMessage);
          },
        );

    // Configure channel based on connection quality
    _configureChannelForConnection(channel);
    
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Successfully subscribed to $channelKey
      } else if (error != null) {
        // Subscription error for $channelKey: $error
        _handleSubscriptionError(channelKey, onMessage);
      }
    });

    _activeChannels[channelKey] = channel;
    return channel;
  }

  PostgresChangeFilter? _buildMessageFilter(String? userId, String? businessId) {
    if (businessId != null) {
      return PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'business_id',
        value: businessId,
      );
    }
    return null;
  }

  void _configureChannelForConnection(RealtimeChannel channel) {
    final quality = _connectionService.currentQuality;
    
    // Adjust heartbeat and timeout based on connection
    switch (quality) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        // Fast updates for good connections
        break;
      case ConnectionQuality.fair:
        // Moderate throttling
        break;
      case ConnectionQuality.poor:
      case ConnectionQuality.offline:
        // Heavy throttling or disable real-time
        break;
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> message, Function(Map<String, dynamic>) onMessage) {
    // Decompress if needed
    if (message['is_compressed'] == true) {
      message['content'] = _decompressMessage(message['content']);
    }

    // Cache message for offline scenarios
    final conversationKey = '${message['business_id']}_${message['sender_id']}_${message['receiver_id']}';
    _cacheMessage(conversationKey, message);

    // Emit to stream and callback
    _messageController.add(message);
    onMessage(message);
  }

  void _handleMessageUpdate(Map<String, dynamic> message, Function(Map<String, dynamic>) onMessage) {
    // Handle message status updates (delivered, read, etc.)
    _messageController.add({...message, 'isUpdate': true});
    onMessage({...message, 'isUpdate': true});
  }

  void _handleSubscriptionError(String channelKey, Function(Map<String, dynamic>) onMessage) {
    // Implement exponential backoff retry
    Timer(const Duration(seconds: 2), () {
      if (_activeChannels.containsKey(channelKey)) {
        _activeChannels[channelKey]?.unsubscribe();
        _activeChannels.remove(channelKey);
        // Retry subscription logic here
      }
    });
  }

  void _cacheMessage(String conversationKey, Map<String, dynamic> message) {
    _messageCache.putIfAbsent(conversationKey, () => []);
    _messageCache[conversationKey]!.add(message);
    
    // Keep only last 50 messages in cache
    if (_messageCache[conversationKey]!.length > 50) {
      _messageCache[conversationKey]!.removeAt(0);
    }
  }

  List<Map<String, dynamic>>? getCachedMessages(String conversationKey) {
    return _messageCache[conversationKey];
  }

  String _decompressMessage(String compressed) {
    try {
      final bytes = base64Decode(compressed);
      return utf8.decode(bytes);
    } catch (e) {
      return compressed;
    }
  }

  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      // Clean up old cache entries
      _messageCache.removeWhere((key, messages) => 
        messages.isEmpty || 
        DateTime.now().difference(DateTime.parse(messages.last['created_at'])).inHours > 1
      );
    });
  }

  void unsubscribeFromConversation(String conversationId) {
    final channelKey = 'conversation_$conversationId';
    _activeChannels[channelKey]?.unsubscribe();
    _activeChannels.remove(channelKey);
  }
}