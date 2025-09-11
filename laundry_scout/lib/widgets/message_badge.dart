import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageBadge extends StatefulWidget {
  final Widget child;
  final String userId;

  const MessageBadge({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<MessageBadge> createState() => _MessageBadgeState();
}

class _MessageBadgeState extends State<MessageBadge> {
  int _unreadCount = 0;
  late RealtimeChannel _messageSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageSubscription.unsubscribe();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      // Count unread messages where the user is the receiver
      final response = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('receiver_id', widget.userId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _unreadCount = response.length;
        });
      }
    } catch (e) {
      // Error loading message count
      print('Error loading unread message count: $e');
    }
  }

  void _setupRealtimeSubscription() {
    _messageSubscription = Supabase.instance.client
        .channel('messages_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: widget.userId,
          ),
          callback: (payload) {
            _debounceRefresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: widget.userId,
          ),
          callback: (payload) {
            _debounceRefresh();
          },
        )
        .subscribe();
  }

  void _debounceRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}