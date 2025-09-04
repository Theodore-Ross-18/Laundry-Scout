import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:developer';
import '../../../services/connection_service.dart';
import '../../../services/message_queue_service.dart';
import '../../../services/realtime_message_service.dart';
import '../../../widgets/optimized_image.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  late RealtimeChannel _messagesSubscription;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredConversations = [];
  Timer? _backgroundRefreshTimer; // Add background refresh timer

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupRealtimeSubscription();
    _startBackgroundRefresh(); // Start background refresh
  }

  @override
  void dispose() {
    _messagesSubscription.unsubscribe();
    _backgroundRefreshTimer?.cancel(); // Cancel timer
    _searchController.dispose();
    super.dispose();
  }

  // Add background refresh method
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) { // Changed from 2 seconds to 10
      if (mounted) {
        _refreshConversationsInBackground();
      }
    });
  }

  // Background refresh method
  Future<void> _refreshConversationsInBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('conversations')
          .select('''
            *,
            business_profiles(
              business_name,
              cover_photo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false);

      // Get last message for each conversation
      for (var conversation in response) {
        final lastMessage = await Supabase.instance.client
            .from('messages')
            .select('content, created_at, sender_id')
            .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
            .eq('business_id', conversation['business_id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        conversation['last_message'] = lastMessage;
      }

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(response);
          // Preserve search filter
          if (_searchController.text.isEmpty) {
            _filteredConversations = _conversations;
          } else {
            _filterConversations(_searchController.text);
          }
        });
      }
    } catch (e) {
      log('Background refresh error: $e');
    }
  }

  Future<void> _loadConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      final response = await Supabase.instance.client
          .from('conversations')
          .select('''
            *,
            business_profiles(
              business_name,
              cover_photo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false);

      // Get last message for each conversation
      for (var conversation in response) {
        final lastMessage = await Supabase.instance.client
            .from('messages')
            .select('content, created_at, sender_id')
            .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
            .eq('business_id', conversation['business_id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        conversation['last_message'] = lastMessage;
      }

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(response);
          _filteredConversations = _conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    _messagesSubscription = Supabase.instance.client
        .channel('messages_global') // Keep same channel name
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _loadConversations();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations', 
          callback: (payload) {
            _loadConversations();
          },
        )
        .subscribe();
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          final businessName = conversation['business_profiles']['business_name']?.toLowerCase() ?? '';
          return businessName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToChat(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          businessId: conversation['business_id'],
          businessName: conversation['business_profiles']['business_name'],
          businessImage: conversation['business_profiles']['cover_photo_url'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B61FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Laundry Scout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Messages section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Mark all as read functionality
                    },
                    child: const Text(
                      'Mark all as Read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Messages list
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
                    : _filteredConversations.isEmpty
                        ? const Center(
                            child: Text(
                              'No conversations yet',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _filteredConversations[index];
                              final business = conversation['business_profiles'];
                              final lastMessage = conversation['last_message'];
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: InkWell(
                                  onTap: () => _navigateToChat(conversation),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Avatar with online indicator
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: Colors.grey[200],
                                              child: business['cover_photo_url'] != null
                                                  ? ClipOval(
                                                      child: OptimizedImage(
                                                        imageUrl: business['cover_photo_url'],
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        placeholder: const Icon(Icons.business, color: Colors.grey),
                                                      ),
                                                    )
                                                  : const Icon(Icons.business, color: Colors.grey, size: 30),
                                            ),
                                            // Online indicator (green dot)
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        // Message content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    business['business_name'] ?? 'Business',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  if (lastMessage != null)
                                                    Text(
                                                      _formatTime(lastMessage['created_at']),
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lastMessage?['content'] ?? 'No messages yet',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            // Feedback button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showFeedbackModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showFeedbackModal() {
    showDialog(
      context: context,
      builder: (context) => const FeedbackModal(),
    );
  }
}

// Chat Screen for individual conversations
class ChatScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String? businessImage;

  const ChatScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    this.businessImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  final RealtimeMessageService _realtimeService = RealtimeMessageService();
  final ConnectionService _connectionService = ConnectionService();
  final MessageQueueService _messageQueue = MessageQueueService();
  ConnectionQuality _connectionQuality = ConnectionQuality.good;
  late StreamSubscription _qualitySubscription;
  late StreamSubscription _messageSubscription;
  RealtimeChannel? _currentChannel;
  Timer? _backgroundRefreshTimer; // Add background refresh timer

  @override
  void initState() {
    super.initState();
    _realtimeService.initialize();
    _connectionService.startMonitoring();
    _messageQueue.startQueue();
    _loadMessages();
    _setupRealtimeSubscription();
    _setupQualityListener();
    _startBackgroundRefresh(); // Start background refresh
  }

  @override
  void dispose() {
    _currentChannel?.unsubscribe();
    _qualitySubscription.cancel();
    _messageSubscription.cancel();
    _connectionService.stopMonitoring();
    _messageQueue.stopQueue();
    _backgroundRefreshTimer?.cancel(); // Cancel timer
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Add background refresh for messages
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _refreshMessagesInBackground();
      }
    });
  }

  // Background refresh method for messages
  Future<void> _refreshMessagesInBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: true);

      if (mounted) {
        final newMessages = List<Map<String, dynamic>>.from(response);
        
        // Only update if there are new messages
        if (newMessages.length != _messages.length || 
            (newMessages.isNotEmpty && _messages.isNotEmpty && 
             newMessages.last['id'] != _messages.last['id'])) {
          setState(() {
            _messages = newMessages;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      log('Background message refresh error: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _currentChannel = _realtimeService.subscribeToConversation(
      '${user.id}_${widget.businessId}',
      userId: user.id,
      businessId: widget.businessId,
      onMessage: (message) {
        if (mounted) {
          setState(() {
            // Remove optimistic message if it exists
            _messages.removeWhere((msg) => msg['is_sending'] == true && 
                msg['content'] == message['content']);
            _messages.add(message);
          });
          _scrollToBottom();
        }
      },
    );

    // Listen to sent messages for optimistic update confirmation
    _messageSubscription = _messageQueue.sentMessageStream.listen((sentMessage) {
      if (mounted) {
        setState(() {
          // Update optimistic message to confirmed
          final index = _messages.indexWhere((msg) => 
              msg['tempId'] == sentMessage.tempId);
          if (index != -1) {
            _messages[index]['is_sending'] = false;
            _messages[index]['id'] = sentMessage.id;
          }
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Optimistic update
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final tempId = _messageQueue.queueMessage(
        content: content,
        receiverId: widget.businessId,
        businessId: widget.businessId,
      );

      final optimisticMessage = {
        'tempId': tempId,
        'sender_id': user.id,
        'receiver_id': widget.businessId,
        'business_id': widget.businessId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'is_sending': true,
      };
      
      setState(() {
        _messages.add(optimisticMessage);
      });
      _scrollToBottom();
    }
  }

  Widget _buildConnectionIndicator() {
    Color color = Colors.grey;
    String text = 'Unknown';
    IconData icon = Icons.signal_cellular_off;
    
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        color = Colors.green;
        text = 'Excellent';
        icon = Icons.signal_cellular_4_bar;
        break;
      case ConnectionQuality.good:
        color = Colors.lightGreen;
        text = 'Good';
        icon = Icons.signal_cellular_4_bar;
        break;
      case ConnectionQuality.fair:
        color = Colors.orange;
        text = 'Fair';
        icon = Icons.signal_cellular_alt;
        break;
      case ConnectionQuality.poor:
        color = Colors.red;
        text = 'Poor';
        icon = Icons.signal_cellular_connected_no_internet_0_bar;
        break;
      case ConnectionQuality.offline:
        color = Colors.grey;
        text = 'Offline';
        icon = Icons.signal_cellular_off;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B61FF),
        title: Row(
          children: [
            CircleAvatar(
               radius: 20,
               backgroundColor: const Color.fromRGBO(255, 255, 255, 0.2),
               child: widget.businessImage != null
                   ? ClipOval(
                       child: OptimizedImage(
                         imageUrl: widget.businessImage!,
                         width: 40,
                         height: 40,
                         fit: BoxFit.cover,
                         placeholder: const Icon(Icons.business, color: Colors.white),
                       ),
                     )
                   : const Icon(Icons.business, color: Colors.white),
             ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildConnectionIndicator(),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id'] == user?.id;
                final isSending = message['is_sending'] == true;
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Business/Owner avatar (left side for incoming messages)
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: widget.businessImage != null
                                ? ClipOval(
                                    child: OptimizedImage(
                                      imageUrl: widget.businessImage!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      placeholder: const Icon(Icons.business, size: 16, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.business, size: 16, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // Message content
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Sender name
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                                  child: Text(
                                    widget.businessName,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              
                              // Message bubble
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF7B61FF) : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                ),
                                child: Text(
                                  message['content'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              
                              // Time and delivery status
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatMessageTime(message['created_at']),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        isSending ? Icons.access_time : Icons.done,
                                        size: 14,
                                        color: isSending ? Colors.orange : Colors.green,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // User avatar (right side for outgoing messages)
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF7B61FF),
                            child: Text(
                              user?.userMetadata?['full_name']?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(51, 0, 0, 0),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(46, 255, 255, 255),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B61FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
        });
        _scrollToBottom();
      }
    } catch (e) {
      log('Error loading messages: $e');
    }
  }

  void _setupQualityListener() {
    _qualitySubscription = _connectionService.qualityStream.listen((quality) {
      if (mounted) {
        setState(() {
          _connectionQuality = quality;
        });
      }
    });
  }

  String _formatMessageTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Convert to 12-hour format
    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    
    String timeString = '${hour.toString()}:${dateTime.minute.toString().padLeft(2, '0')} $period';

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} $timeString';
    } else {
      return timeString;
    }
  }
    
}

// Feedback Modal
class FeedbackModal extends StatefulWidget {
  const FeedbackModal({super.key});

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  final TextEditingController _feedbackController = TextEditingController();
  List<Map<String, dynamic>> _businesses = [];
  String? _selectedBusinessId;
  int _rating = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name')
          .order('business_name');

      if (mounted) {
        setState(() {
          _businesses = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      log('Error loading businesses: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedBusinessId == null || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business and enter feedback')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('feedback').insert({
        'user_id': user.id,
        'business_id': _selectedBusinessId,
        'rating': _rating,
        'comment': _feedbackController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
      }
    } catch (e) {
      log('Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give Us Your Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you have any thoughts you would like to share?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Business selection
            DropdownButtonFormField<String>(
              value: _selectedBusinessId,
              decoration: InputDecoration(
                labelText: 'Select Business',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _businesses.map((business) {
                return DropdownMenuItem<String>(
                  value: business['id'],
                  child: Text(business['business_name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusinessId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    color: index < _rating ? Colors.orange : Colors.grey[300],
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Feedback text
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share Your Thoughts Here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}