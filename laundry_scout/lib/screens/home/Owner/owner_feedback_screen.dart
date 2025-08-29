import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OwnerFeedbackScreen extends StatefulWidget {
  const OwnerFeedbackScreen({super.key});

  @override
  State<OwnerFeedbackScreen> createState() => _OwnerFeedbackScreenState();
}

class _OwnerFeedbackScreenState extends State<OwnerFeedbackScreen> {
  List<Map<String, dynamic>> _feedback = [];
  bool _isLoading = true;
  late StreamSubscription _feedbackSubscription;
  double _averageRating = 0.0;
  int _totalFeedback = 0;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _feedbackSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('feedback')
          .select('''
            *,
            business_profiles!inner(
              business_name,
              cover_photo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _feedback = List<Map<String, dynamic>>.from(response);
          _calculateStats();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStats() {
    if (_feedback.isEmpty) {
      _averageRating = 0.0;
      _totalFeedback = 0;
      return;
    }

    _totalFeedback = _feedback.length;
    double totalRating = _feedback.fold(0.0, (sum, feedback) => sum + feedback['rating']);
    _averageRating = totalRating / _totalFeedback;
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _feedbackSubscription = Supabase.instance.client
        .from('feedback')
        .stream(primaryKey: ['id'])
        .eq('business_id', user.id)
        .listen((data) {
          _loadFeedback();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'Feedback',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B61FF),
                            ),
                          ),
                          const Text(
                            'Average Rating',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 20,
                                color: index < _averageRating
                                    ? Colors.orange
                                    : Colors.grey[300],
                              );
                            }),
                          ),
                        ],
                      ),
                      Container(
                        height: 60,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      Column(
                        children: [
                          Text(
                            _totalFeedback.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B61FF),
                            ),
                          ),
                          const Text(
                            'Total Reviews',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Feedback List
                Expanded(
                  child: _feedback.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No feedback yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Feedback from customers will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _feedback.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedback[index];
                            final business = feedback['business_profiles'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: business['cover_photo_url'] != null
                                            ? NetworkImage(business['cover_photo_url'])
                                            : null,
                                        child: business['cover_photo_url'] == null
                                            ? const Icon(Icons.business, color: Colors.white)
                                            : null,
                                        backgroundColor: const Color(0xFF7B61FF),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              business['business_name'] ?? 'Anonymous',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(feedback['created_at']),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            Icons.star,
                                            size: 16,
                                            color: starIndex < feedback['rating']
                                                ? Colors.orange
                                                : Colors.grey[300],
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    feedback['comment'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}