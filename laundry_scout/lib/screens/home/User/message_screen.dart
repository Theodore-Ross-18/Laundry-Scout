// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
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
  Timer? _backgroundRefreshTimer;
  Timer? _feedbackTimer; // Added feedback timer
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupRealtimeSubscription();
    _startBackgroundRefresh();
    _checkAndShowFeedbackModal();
  }

  @override
  void dispose() {
    _messagesSubscription.unsubscribe();
    _backgroundRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) { // Changed from 2 seconds to 10
      if (mounted) {
        _refreshConversationsInBackground();
      }
    });
  }

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
              cover_photo_url,
              owner_is_online
            )
          ''')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false);

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
              cover_photo_url,
              owner_is_online
            )
          ''')
          .eq('user_id', user.id)
          .order('last_message_at', ascending: false);

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
        .channel('messages_global') 
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
      backgroundColor: const Color(0xFF5A35E3),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
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
                  IconButton(
                    icon: const Icon(Icons.mark_email_read, color: Colors.white),
                    onPressed: _markAllAsRead,
                    tooltip: 'Mark all as read',
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
                                          
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: (business['owner_is_online'] ?? false) == true
                                                  ? Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      business['business_name'] ?? 'Business',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  if (lastMessage != null)
                                                    Flexible(
                                                      child: Text(
                                                        _formatTime(lastMessage['created_at']),
                                                        style: TextStyle(
                                                          color: Colors.grey[500],
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
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

  Future<void> _checkAndShowFeedbackModal() async {
    if (!_sessionService.hasShownUserFeedbackModalThisSession) {
      _feedbackTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) {
          _showFeedbackModal();
          _sessionService.hasShownUserFeedbackModalThisSession = true;
        }
      });
    }
  }

  void _showFeedbackModal() {
    showDialog(
      context: context,
      builder: (context) => FeedbackModal(userId: Supabase.instance.client.auth.currentUser!.id),
    );
  }

  void _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      log('Mark all as read pressed for user: ${user.id}');

    } catch (e) {
      log('Error marking all messages as read: $e');
    }
  }
}

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
  Timer? _backgroundRefreshTimer;
  Timer? _businessStatusTimer;
  String? _userUsername;
  String? _userProfileImage;
  static bool _isNavigatingToChatAssist = false; // Prevent multiple navigations
 

  @override
  void initState() {
    super.initState();
    _realtimeService.initialize();
    _connectionService.startMonitoring();
    _messageQueue.startQueue();
    _loadUserProfile();
    _loadMessages();
    _setupRealtimeSubscription();
    _setupQualityListener();
    _startBackgroundRefresh();
    _startBusinessStatusRefresh();
    _checkBusinessOnlineStatus();
  }

  @override
  void dispose() {
    _currentChannel?.unsubscribe();
    _qualitySubscription.cancel();
    _messageSubscription.cancel();
    _connectionService.stopMonitoring();
    _messageQueue.stopQueue();
    _backgroundRefreshTimer?.cancel();
    _businessStatusTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isNavigatingToChatAssist) {
        _refreshMessagesInBackground();
      }
    });
  }

  void _startBusinessStatusRefresh() {
    _businessStatusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isNavigatingToChatAssist) {
        _checkBusinessOnlineStatus();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('username, profile_image_url')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userUsername = response['username'] ?? 'You';
          _userProfileImage = response['profile_image_url'];
        });
      }
    } catch (e) {
      log('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _userUsername = 'You';
        });
      }
    }
  }

  Future<void> _refreshMessagesInBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Refresh messages
      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .eq('business_id', widget.businessId)
          .order('created_at', ascending: true);

      if (mounted) {
        final newMessages = List<Map<String, dynamic>>.from(response);
        
        if (newMessages.length != _messages.length || 
            (newMessages.isNotEmpty && _messages.isNotEmpty && 
             newMessages.last['id'] != _messages.last['id'])) {
          setState(() {
            _messages = newMessages;
          });
          _scrollToBottom();
        }
      }

      // Also refresh business online status in background (only if not already navigating)
      if (!_isNavigatingToChatAssist) {
        await _checkBusinessOnlineStatus();
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
            
            _messages.removeWhere((msg) => msg['is_sending'] == true && 
                msg['content'] == message['content']);
            _messages.add(message);
          });
          _scrollToBottom();
        }
      },
    );

    // Add realtime subscription for business profile changes (online/offline status)
    Supabase.instance.client
        .channel('business_profile_${widget.businessId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'business_profiles',
          callback: (payload) {
            if (mounted && payload.newRecord['id'] == widget.businessId) {
              // Handle online status change - navigation will be handled elsewhere
            }
          },
        )
        .subscribe();

    _messageSubscription = _messageQueue.sentMessageStream.listen((sentMessage) {
      if (mounted) {
        setState(() {
         
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
    return StreamBuilder<List<Map<String, dynamic>>>( // Use StreamBuilder for real-time updates
      stream: _streamBusinessLoginStatus(widget.businessId), // Stream login status for the business
      builder: (context, snapshot) {
        bool isOnline = false;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          isOnline = snapshot.data![0]['owner_is_online'] == true; // Check 'owner_is_online' field
        }

        Color color = isOnline ? Colors.green : const Color.fromARGB(255, 222, 0, 0);
        String text = isOnline ? 'Online' : 'Offline';
        IconData icon = isOnline ? Icons.circle : Icons.circle_outlined;

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
                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _streamBusinessLoginStatus(String businessId) {
    return Supabase.instance.client
        .from('business_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', businessId)
        .order('id', ascending: true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A35E3),
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
                        
                    
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                             
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 4,
                                  left: isMe ? 0 : 8,
                                  right: isMe ? 8 : 0,
                                ),
                                child: Text(
                                  isMe ? ( 'You') : widget.businessName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                             
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFF5A35E3) : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12),
                                      topRight: const Radius.circular(12),
                                      bottomLeft: Radius.circular(isMe ? 12 : 2),
                                      bottomRight: Radius.circular(isMe ? 2 : 12),
                                    ),
                                  ),
                                  child: Text(
                                    message['content'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              
                             
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
                                        isSending ? Icons.access_time : Icons.done_all,
                                        size: 14,
                                        color: isSending ? Colors.orange : Colors.blue,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF5A35E3),
                            child: _userProfileImage != null
                                ? ClipOval(
                                    child: OptimizedImage(
                                      imageUrl: _userProfileImage!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      placeholder: Text(
                                        _userUsername?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _userUsername?.substring(0, 1).toUpperCase() ?? 'U',
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
              color: const Color.fromARGB(255, 255, 255, 255),
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
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF5A35E3)),
                  onPressed: () {
                    // Handle camera action
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFF5A35E3)),
                  onPressed: () {
                    // Handle photo action
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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
                      color: Color(0xFF5A35E3),
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
  
  Future<void> _checkBusinessOnlineStatus() async {
    // Prevent multiple navigations
    if (_isNavigatingToChatAssist) return;
    
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('owner_is_online')
          .eq('id', widget.businessId)
          .single();
      
      if (mounted) {
        final isOffline = !(response['owner_is_online'] ?? true);
        if (isOffline && !_isNavigatingToChatAssist) {
          // Set flag to prevent multiple navigations
          _isNavigatingToChatAssist = true;
          
          // Navigate to chat assistant when business is offline
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatAssistWidget(
                businessName: widget.businessName,
                businessId: widget.businessId,
              ),
            ),
          ).then((_) {
            // Reset flag when navigation completes
            _isNavigatingToChatAssist = false;
          });
        }
      }
    } catch (e) {
      log('Error checking business online status: $e');
      // Reset flag on error
      _isNavigatingToChatAssist = false;
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

// Chat Assist Widget for offline business owners - Now with AI chat functionality
class ChatAssistWidget extends StatefulWidget {
  final String businessId;
  final String businessName;

  const ChatAssistWidget({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ChatAssistWidget> createState() => _ChatAssistWidgetState();
}

class _ChatAssistWidgetState extends State<ChatAssistWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isTyping = false;
  Map<String, dynamic>? _businessData;
  bool _isLoadingData = true;
  DateTime? _lastMessageTime;
  static const Duration _messageCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('*, service_prices, services_offered, open_hours, business_phone_number, business_address, about_business, does_delivery, delivery_fee')
          .eq('id', widget.businessId)
          .single();

      setState(() {
        _businessData = response;
        _isLoadingData = false;
      });
    } catch (e) {
      log('Error loading business data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _chatMessages.add({
        'isBot': true,
        'message': 'Hello! I\'m ${widget.businessName}\'s assistant. I can help you with information about our services, prices, business hours, and more. What would you like to know?',
        'timestamp': DateTime.now(),
      });
    });
  }

  void _handleUserMessage(String message) {
    if (message.trim().isEmpty) return;
    
    // Prevent processing if already typing (prevents spam)
    if (_isTyping) {
      return;
    }
    
    // Rate limiting: Check if enough time has passed since last message
    final now = DateTime.now();
    if (_lastMessageTime != null && now.difference(_lastMessageTime!) < _messageCooldown) {
      return; // Too soon, ignore this message
    }
    
    _lastMessageTime = now;

    setState(() {
      _chatMessages.add({
        'isBot': false,
        'message': message.trim(),
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();

    // Generate response immediately (typing indicator will handle the delay)
    _generateBotResponse(message.trim().toLowerCase());
  }

  void _generateBotResponse(String userMessage) {
    if (_businessData == null) {
      _addBotMessage('I\'m sorry, but I couldn\'t load the business information. Please try again later.');
      return;
    }

    // Add typing indicator
    setState(() {
      _chatMessages.add({
        'isBot': true,
        'message': '',
        'isTyping': true,
        'timestamp': DateTime.now(),
      });
    });

    // Simulate processing time
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Remove typing indicator
      setState(() {
        _chatMessages.removeWhere((msg) => msg['isTyping'] == true);
      });

      String response = _processUserQuery(userMessage);
      _addBotMessage(response);
    });
  }

  String _processUserQuery(String query) {
    // Price-related questions
    if (query.contains('price') || query.contains('cost') || query.contains('how much')) {
      return _getPriceInformation(query);
    }
    
    // Service-related questions
    if (query.contains('service') || query.contains('what do you offer') || query.contains('available')) {
      return _getServiceInformation();
    }
    
    // Hours-related questions
    if (query.contains('hour') || query.contains('open') || query.contains('close') || query.contains('time')) {
      return _getHoursInformation();
    }
    
    // Location/delivery questions
    if (query.contains('location') || query.contains('address') || query.contains('where')) {
      return _getLocationInformation();
    }
    
    // Delivery questions
    if (query.contains('delivery') || query.contains('deliver')) {
      return _getDeliveryInformation();
    }
    
    // Contact questions
    if (query.contains('contact') || query.contains('phone') || query.contains('call')) {
      return _getContactInformation();
    }
    
    // About business
    if (query.contains('about') || query.contains('tell me')) {
      return _getAboutInformation();
    }
    
    // Default response
    return 'I\'m here to help! You can ask me about our services, prices, business hours, location, delivery options, or contact information. What would you like to know?';
  }

  String _getPriceInformation(String query) {
    final servicePrices = _businessData!['service_prices'] as List<dynamic>?;
    if (servicePrices == null || servicePrices.isEmpty) {
      return 'I don\'t have specific pricing information available at the moment. Please contact us directly for pricing details.';
    }

    // Check if user asked about a specific service
    for (var item in servicePrices) {
      if (item is Map<String, dynamic>) {
        String serviceName = item['service']?.toString().toLowerCase() ?? '';
        String price = item['price']?.toString() ?? '0';
        
        // Check if query mentions this specific service
        if (query.contains(serviceName.toLowerCase())) {
          return 'Our ${item['service']} service costs ₱${double.parse(price).toStringAsFixed(2)}.';
        }
      }
    }

    // General price response
    String priceList = servicePrices.map((item) {
      if (item is Map<String, dynamic>) {
        String service = item['service'] ?? 'Service';
        String price = item['price']?.toString() ?? '0';
        return '• $service: ₱${double.parse(price).toStringAsFixed(2)}';
      }
      return '';
    }).join('\n');

    return 'Here are our service prices:\n$priceList\n\nPrices may vary based on specific requirements.';
  }

  String _getServiceInformation() {
    final servicesOffered = _businessData!['services_offered'];
    final servicePrices = _businessData!['service_prices'] as List<dynamic>?;
    
    String serviceList = '';
    if (servicePrices != null && servicePrices.isNotEmpty) {
      serviceList = servicePrices.map((item) {
        if (item is Map<String, dynamic>) {
          return '• ${item['service'] ?? 'Service'}';
        }
        return '';
      }).join('\n');
    } else if (servicesOffered is List) {
      serviceList = servicesOffered.map((service) => '• $service').join('\n');
    } else if (servicesOffered is String) {
      serviceList = '• $servicesOffered';
    }

    return 'We offer the following laundry services:\n$serviceList\n\nEach service is designed to meet your specific laundry needs with quality care.';
  }

  String _getHoursInformation() {
    final openHours = _businessData!['open_hours'];
    if (openHours == null || openHours.toString().isEmpty) {
      return 'Our business hours are not specified. Please contact us directly for our operating hours.';
    }
    return 'Our business hours are:\n$openHours\n\nWe\'re here to serve you during these times. Feel free to drop off or pick up your laundry!';
  }

  String _getLocationInformation() {
    final address = _businessData!['business_address'] ?? 'Address not specified';
    return 'You can find us at:\n$address\n\nWe\'re conveniently located to serve your laundry needs. Feel free to visit us!';
  }

  String _getDeliveryInformation() {
    final doesDelivery = _businessData!['does_delivery'] ?? false;
    final deliveryFee = _businessData!['delivery_fee'];
    
    if (!doesDelivery) {
      return 'We currently do not offer delivery services. Please visit our location to drop off and pick up your laundry.';
    }
    
    if (deliveryFee != null && deliveryFee > 0) {
      return 'Yes, we offer delivery services! The delivery fee is ₱${double.parse(deliveryFee.toString()).toStringAsFixed(2)}. We\'ll deliver your clean laundry right to your doorstep.';
    }
    
    return 'Yes, we offer free delivery services! We\'ll deliver your clean laundry right to your doorstep at no extra cost.';
  }

  String _getContactInformation() {
    final phoneNumber = _businessData!['business_phone_number'];
    if (phoneNumber == null || phoneNumber.toString().isEmpty) {
      return 'I don\'t have our phone number available. Please visit our location or check our business profile for contact details.';
    }
    return 'You can reach us at: $phoneNumber\n\nFeel free to call us for any questions, scheduling, or special requests!';
  }

  String _getAboutInformation() {
    final aboutBusiness = _businessData!['about_business'];
    if (aboutBusiness == null || aboutBusiness.toString().isEmpty) {
      return '${widget.businessName} is your trusted local laundry service provider. We\'re committed to providing high-quality laundry care with convenient service options.';
    }
    return aboutBusiness.toString();
  }

  void _addBotMessage(String message) {
    setState(() {
      _isTyping = false;
      _chatMessages.add({
        'isBot': true,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A35E3),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat Assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.businessName} is currently offline',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
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
          // Chat messages area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = _chatMessages[index];
                        return _buildChatMessage(message);
                      },
                    ),
                  ),
                  
                  // Typing indicator
                  if (_isTyping)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isTyping ? 'Assistant is typing...' : 'Ask about services, prices, hours...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _isTyping ? Colors.grey[200] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      hintStyle: TextStyle(
                        color: _isTyping ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    enabled: !_isTyping,
                    onSubmitted: _handleUserMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A35E3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isTyping ? null : () => _handleUserMessage(_messageController.text),
                    icon: Icon(Icons.send, color: _isTyping ? Colors.white.withValues(alpha: 0.5) : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Quick suggestions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick questions you can ask:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickQuestion('Services'),
                      const SizedBox(width: 8),
                      _buildQuickQuestion('Prices'),
                      const SizedBox(width: 8),
                      _buildQuickQuestion('Hours'),
                      const SizedBox(width: 8),
                      _buildQuickQuestion('Location'),
                      const SizedBox(width: 8),
                      _buildQuickQuestion('Delivery'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    final isTyping = message['isTyping'] as bool? ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF5A35E3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFF5A35E3),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF5A35E3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBot ? Colors.grey[300]! : Colors.transparent,
                ),
              ),
              child: isTyping
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message['message'] as String,
                      style: TextStyle(
                        color: isBot ? Colors.black87 : Colors.white,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF5A35E3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF5A35E3),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickQuestion(String question) {
    return GestureDetector(
      onTap: () {
        // Only handle if not currently typing (prevents spam)
        if (!_isTyping) {
          _messageController.text = question.toLowerCase();
          _handleUserMessage(question.toLowerCase());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isTyping 
              ? const Color(0xFF5A35E3).withValues(alpha: 0.05)
              : const Color(0xFF5A35E3).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isTyping
                ? const Color(0xFF5A35E3).withValues(alpha: 0.1)
                : const Color(0xFF5A35E3).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: _isTyping 
                ? const Color(0xFF5A35E3).withValues(alpha: 0.5)
                : const Color(0xFF5A35E3),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


}

class FeedbackModal extends StatefulWidget {
  final String? userId;
  const FeedbackModal({super.key, this.userId});

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 3; // Changed initial rating to 3
  bool _isSubmitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to submit feedback'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

    
      await Supabase.instance.client.from('feedback').insert({
        'user_id': user.id,
        'business_id': null,
        'rating': _rating,
        'comment': _feedbackController.text.trim(),
        'feedback_type': 'admin',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white, // Changed from gradient to white
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give Us Your Feedback',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Do you have any thoughts you would\nlike to share?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Removed 'Rate your experience' text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            // Feedback text area
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
                decoration: const InputDecoration(
                  hintText: 'Leave Your Thoughts Here...',
                  hintStyle: TextStyle(
                    color: Color(0xFFA0AEC0),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 16, // Changed font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFF5A35E3), // Changed to solid color
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A35E3).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitted ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isSubmitted
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Changed font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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