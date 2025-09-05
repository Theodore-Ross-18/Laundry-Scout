import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final String userId;
  
  const NotificationBadge({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  late RealtimeChannel _notificationSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _notificationSubscription.unsubscribe();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _unreadCount = response.length;
        });
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  void _setupRealtimeSubscription() {
    _notificationSubscription = Supabase.instance.client
        .channel('notification_badge_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            _debounceRefresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
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