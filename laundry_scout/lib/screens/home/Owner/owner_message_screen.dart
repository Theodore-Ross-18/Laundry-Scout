// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../services/session_service.dart';
import '../../../services/connection_service.dart';
import '../../../services/realtime_message_service.dart';
import '../../../services/message_queue_service.dart';
import '../../../widgets/optimized_image.dart';

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
  Timer? _backgroundRefreshTimer;
  Timer? _feedbackTimer; // Added feedback timer
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    print('OwnerMessageScreen initState called');
    _loadConversations();
    _setupRealtimeSubscription();
    _startBackgroundRefresh();
    // Add a small delay to ensure the screen is fully built and user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Screen built, checking feedback modal...');
      // Add a small additional delay to ensure everything is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndShowFeedbackModal();
        }
      });
    });
  }

  @override
  void dispose() {
    _messagesSubscription.unsubscribe();
    _backgroundRefreshTimer?.cancel();
    _searchController.dispose();
    _feedbackTimer?.cancel();
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
      final conversationsResponse = await Supabase.instance.client
          .from('conversations')
          .select('*')
          .eq('business_id', Supabase.instance.client.auth.currentUser!.id)
          .order('last_message_at', ascending: false);
  
      for (var conversation in conversationsResponse) {
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
         
          if (_searchController.text.isEmpty) {
            _filteredConversations = _conversations;
          } else {
            _filterConversations(_searchController.text);
          }
        });
      }
    } catch (e) {
      print('Background refresh error: $e');
     
    }
  }

  
  String _getDisplayName(Map<String, dynamic>? user, String userId) {
    if (user == null) {
      return 'User${userId.substring(0, 8)}';
    }
    
    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    if (fullName.isNotEmpty) {
      return fullName;
    } else if (user['username'] != null && user['username'].toString().isNotEmpty) {
      return user['username'];
    } else if (user['email'] != null && user['email'].toString().isNotEmpty) {
      final email = user['email'].toString();
      return email.split('@').first;
    } else {
      return 'User${userId.substring(0, 8)}';
    }
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });
  
      final conversationsResponse = await Supabase.instance.client
          .from('conversations')
          .select('*')
          .eq('business_id', Supabase.instance.client.auth.currentUser!.id)
          .order('last_message_at', ascending: false);
  
      for (var conversation in conversationsResponse) {
        print('Conversation user_id: ${conversation['user_id']}');
        
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('username, first_name, last_name, profile_image_url, email')
            .eq('id', conversation['user_id'])
            .maybeSingle();
        
        print('User profile result: $userProfile');
        
        if (userProfile == null) {
         
          conversation['user_profiles'] = {
            'username': 'User${conversation['user_id'].substring(0, 8)}',
            'first_name': null,
            'last_name': null,
            'profile_image_url': null,
            'email': null,
          };
        } else {
          conversation['user_profiles'] = userProfile;
        }

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
          final userName = conversation['user_profiles']?['username']?.toLowerCase() ?? '';
          return userName.contains(query.toLowerCase());
        }).toList();
      }
    });
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
                              final user = conversation['user_profiles'];
                              final lastMessage = conversation['last_message'];
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OwnerChatScreen(
                        userId: conversation['user_id'],
                        userName: _getDisplayName(user, conversation['user_id']),
                        userImage: user?['profile_image_url'],
                      ),
                                      ),
                                    );
                                  },
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
                                              child: user?['profile_image_url'] != null
                                                  ? ClipOval(
                                                      child: OptimizedImage(
                                                        imageUrl: user!['profile_image_url'],
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        placeholder: const Icon(Icons.person, color: Colors.grey),
                                                      ),
                                                    )
                                                  : const Icon(Icons.person, color: Colors.grey, size: 30),
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
                                                  Expanded(
                                                    child: Text(
                                                      _getDisplayName(user, conversation['user_id']),
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
            // Removed feedback button container
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
    print('Checking feedback modal - hasShownOwnerFeedbackModalThisSession: ${_sessionService.hasShownOwnerFeedbackModalThisSession}');
    if (!_sessionService.hasShownOwnerFeedbackModalThisSession) {
      print('Setting feedback timer for 10 seconds...');
      _feedbackTimer = Timer(const Duration(minutes: 20), () {
        print('Feedback timer triggered - mounted: $mounted');
        if (mounted) {
          // Double-check that user is authenticated before showing modal
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser != null) {
            print('Showing feedback modal...');
            _showFeedbackModal();
            _sessionService.hasShownOwnerFeedbackModalThisSession = true;
          } else {
            print('User not authenticated - skipping feedback modal');
          }
        }
      });
    } else {
      print('Feedback modal already shown this session');
    }
  }

  void _showFeedbackModal() {
    print('Showing feedback modal dialog...');
    final currentUser = Supabase.instance.client.auth.currentUser;
    print('Current user: $currentUser');
    
    if (currentUser != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          print('Building BusinessFeedbackModal with businessId: ${currentUser.id}');
          return BusinessFeedbackModal(businessId: currentUser.id);
        },
      ).then((_) {
        print('Feedback modal closed');
      }).catchError((error) {
        print('Error showing feedback modal: $error');
      });
    } else {
      print('No current user found - cannot show feedback modal');
    }
  }

  void _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Placeholder for marking all messages as read.
      // This functionality requires a database change to track message read status.
      print('Mark all as read pressed for user: ${user.id}');

      // Example of a potential database update (currently commented out as 'is_read' column doesn't exist for messages)
      /*
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', user.id)
          .eq('is_read', false);

      // You would also need to update the local state to reflect the changes
      setState(() {
        // Logic to update local message status
      });
      */
    } catch (e) {
      print('Error marking all messages as read: $e');
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
              backgroundColor: Colors.white.withOpacity(0.3),
              child: widget.userImage != null
                  ? ClipOval(
                      child: OptimizedImage(
                        imageUrl: widget.userImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: widget.userImage != null
                                ? ClipOval(
                                    child: OptimizedImage(
                                      imageUrl: widget.userImage!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      placeholder: const Icon(Icons.person, size: 16, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 16, color: Colors.grey),
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
                                  isMe ? (user?.userMetadata?['full_name'] ?? 'You') : widget.userName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                            
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF5A35E3) : Colors.grey[200],
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
                                        Icons.done,
                                        size: 14,
                                        color: Colors.green,
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
                            child: Text(
                              user?.userMetadata?['full_name']?.substring(0, 1).toUpperCase() ?? 'O',
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
              color: const Color(0xFF5A35E3) ,
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

class BusinessFeedbackModal extends StatefulWidget {
  final String businessId;

  const BusinessFeedbackModal({super.key, required this.businessId});

  @override
  State<BusinessFeedbackModal> createState() => _BusinessFeedbackModalState();
}

class _BusinessFeedbackModalState extends State<BusinessFeedbackModal> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 3; // Changed initial rating to 3 to match the image
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    print('BusinessFeedbackModal created with businessId: ${widget.businessId}');
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client
          .from('feedback')
          .insert({
            'business_id': widget.businessId,
            'rating': _rating,
            'comment': _feedbackController.text.trim(),
            'feedback_type': 'business',
            'created_at': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('BusinessFeedbackModal building...');
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
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              style: const TextStyle(color: Colors.black), // Set input text color to black
              decoration: InputDecoration(
                hintText: 'Leave Your Thoughts Here...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A35E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 5,
                      shadowColor: const Color(0xFF5A35E3).withOpacity(0.4),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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