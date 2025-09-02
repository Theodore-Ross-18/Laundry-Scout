import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../services/connection_service.dart';
import '../../../services/realtime_message_service.dart';
import '../../../services/message_queue_service.dart';

class OwnerMessageScreen extends StatefulWidget {
  const OwnerMessageScreen({super.key});

  @override
  State<OwnerMessageScreen> createState() => _OwnerMessageScreenState();
}

class _OwnerMessageScreenState extends State<OwnerMessageScreen> {
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
    _backgroundRefreshTimer?.cancel(); // Cancel timer on dispose
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

  // Background refresh method that doesn't show loading indicator
  Future<void> _refreshConversationsInBackground() async {
    try {
      // Get conversations without showing loading state
      final conversationsResponse = await Supabase.instance.client
          .from('conversations')
          .select('*')
          .eq('business_id', Supabase.instance.client.auth.currentUser!.id)
          .order('last_message_at', ascending: false);
  
      // Process conversations
      for (var conversation in conversationsResponse) {
        // Get user profile
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('username, first_name, last_name, profile_image_url')
            .eq('id', conversation['user_id'])
            .maybeSingle();
        
        if (userProfile == null) {
          conversation['user_profiles'] = {
            'username': 'User${conversation['user_id'].substring(0, 8)}',
            'first_name': null,
            'last_name': null,
            'profile_image_url': null,
          };
        } else {
          conversation['user_profiles'] = userProfile;
        }

        // Get last message for each conversation
        final lastMessage = await Supabase.instance.client
            .from('messages')
            .select('content, created_at, sender_id')
            .eq('business_id', conversation['business_id'])
            .or('sender_id.eq.${conversation['user_id']},receiver_id.eq.${conversation['user_id']}')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        conversation['last_message'] = lastMessage;
      }

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(conversationsResponse);
          // Preserve search filter
          if (_searchController.text.isEmpty) {
            _filteredConversations = _conversations;
          } else {
            _filterConversations(_searchController.text);
          }
        });
      }
    } catch (e) {
      print('Background refresh error: $e');
      // Don't show error to user for background refresh
    }
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });
  
      // First get conversations
      final conversationsResponse = await Supabase.instance.client
          .from('conversations')
          .select('*')
          .eq('business_id', Supabase.instance.client.auth.currentUser!.id)
          .order('last_message_at', ascending: false);
  
      // Then manually fetch user profiles for each conversation
      for (var conversation in conversationsResponse) {
        print('Conversation user_id: ${conversation['user_id']}'); // Debug print
        
        // Get user profile
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('username, first_name, last_name, profile_image_url')
            .eq('id', conversation['user_id'])
            .maybeSingle();
        
        print('User profile result: $userProfile'); // Debug print
        
        // Handle missing user profile gracefully
        if (userProfile == null) {
          // Simply use fallback username without trying to create database record
          conversation['user_profiles'] = {
            'username': 'User${conversation['user_id'].substring(0, 8)}',
            'first_name': null,
            'last_name': null,
            'profile_image_url': null,
          };
        } else {
          conversation['user_profiles'] = userProfile;
        }

        // Get last message for each conversation
        final lastMessage = await Supabase.instance.client
            .from('messages')
            .select('content, created_at, sender_id')
            .eq('business_id', conversation['business_id'])
            .or('sender_id.eq.${conversation['user_id']},receiver_id.eq.${conversation['user_id']}')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        conversation['last_message'] = lastMessage;
      }

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(conversationsResponse);
          _filteredConversations = _conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    _messagesSubscription = Supabase.instance.client
        .channel('messages_global') // Changed from 'owner_messages'
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
          final userName = conversation['user_profiles']?['username']?.toLowerCase() ?? '';
          return userName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B61FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B61FF),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read functionality
            },
            child: const Text(
              'Mark all as Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF7B61FF),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConversations,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
              ),
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
                          padding: const EdgeInsets.only(top: 20),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            final user = conversation['user_profiles'];
                            final lastMessage = conversation['last_message'];
                            
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: user?['profile_image_url'] != null
                                    ? NetworkImage(user!['profile_image_url'])
                                    : null,
                                child: user?['profile_image_url'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                user?['username'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                lastMessage?['content'] ?? 'No messages yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: lastMessage != null
                                  ? Text(
                                      _formatTime(lastMessage['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OwnerChatScreen(
                                      userId: conversation['user_id'],
                                      userName: user?['username'] ?? 'Unknown User',
                                      userImage: user?['profile_image_url'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
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
}

// Owner Chat Screen for individual conversations
class OwnerChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;

  const OwnerChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
  });

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen> {
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
    _setupConnectionQualityListener();
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
          .eq('business_id', user.id)
          .or('sender_id.eq.${widget.userId},receiver_id.eq.${widget.userId}')
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
      print('Background message refresh error: $e');
    }
  }

  void _setupConnectionQualityListener() {
    _qualitySubscription = _connectionService.qualityStream.listen((quality) {
      if (mounted) {
        setState(() {
          _connectionQuality = quality;
        });
      }
    });
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _currentChannel = _realtimeService.subscribeToConversation(
      '${user.id}_${widget.userId}',
      userId: user.id,
      businessId: user.id,
      onMessage: (message) {
        if (mounted && (message['sender_id'] == widget.userId || message['receiver_id'] == widget.userId)) {
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
        receiverId: widget.userId,
        businessId: user.id,
      );

      final optimisticMessage = {
        'tempId': tempId,
        'sender_id': user.id,
        'receiver_id': widget.userId,
        'business_id': user.id,
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

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .eq('business_id', user.id)
          .or('sender_id.eq.${widget.userId},receiver_id.eq.${widget.userId}')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              backgroundImage: widget.userImage != null
                  ? NetworkImage(widget.userImage!)
                  : null,
              child: widget.userImage == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF7B61FF) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['content'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMessageTime(message['created_at']),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
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
              color: const Color(0xFF7B61FF) ,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
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