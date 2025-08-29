import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messagesSubscription.unsubscribe();
    _searchController.dispose();
    super.dispose();
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
            .select('username, profile_image_url')
            .eq('id', conversation['user_id'])
            .maybeSingle();
        
        print('User profile result: $userProfile'); // Debug print
        
        // Handle missing user profile gracefully
        if (userProfile == null) {
          // Simply use fallback username without trying to create database record
          conversation['user_profiles'] = {
            'username': 'User${conversation['user_id'].substring(0, 8)}',
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
        .channel('owner_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
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
  late RealtimeChannel _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription.unsubscribe();
    super.dispose();
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

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _messagesSubscription = Supabase.instance.client
        .channel('owner_chat_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: user.id,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (mounted && (newMessage['sender_id'] == widget.userId || newMessage['receiver_id'] == widget.userId)) {
              setState(() {
                _messages.add(newMessage);
              });
              _scrollToBottom();
            }
          }
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': widget.userId,
        'business_id': user.id,
        'content': _messageController.text.trim(),
      });

      // Check if conversation exists before trying to update
      final existingConversation = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('business_id', user.id)
          .maybeSingle();

      if (existingConversation != null) {
        // Update existing conversation timestamp
        await Supabase.instance.client
            .from('conversations')
            .update({
              'last_message_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', widget.userId)
            .eq('business_id', user.id);
      }

      // Remove notification creation - this should be handled by database triggers
      // or the receiving user's side to avoid RLS policy violations

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
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
              child: Text(
                widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF7B61FF),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}