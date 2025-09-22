import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../services/feedback_service.dart';

class OwnerFeedbackScreen extends StatefulWidget {
  const OwnerFeedbackScreen({super.key});

  @override
  State<OwnerFeedbackScreen> createState() => _OwnerFeedbackScreenState();
}

class _OwnerFeedbackScreenState extends State<OwnerFeedbackScreen> {
  List<Map<String, dynamic>> _feedback = [];
  bool _isLoading = true;
  final FeedbackService _feedbackService = FeedbackService();
  double _averageRating = 0.0;
  int _totalFeedback = 0;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _initializeFeedback();
  }

  @override
  void dispose() {
    if (_businessId != null) {
      _feedbackService.unsubscribeFromFeedback(_businessId!);
    }
    super.dispose();
  }

  Future<void> _initializeFeedback() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _businessId = await _feedbackService.getBusinessIdForOwner(user.id);
      if (_businessId == null) {
        print('No business ID found for user: ${user.id}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('Business ID initialized: ${_businessId}');
      // Load initial feedback
      await _loadFeedback();

      // Setup real-time subscription
      _feedbackService.subscribeToFeedback(_businessId!, (feedback) {
        print('Real-time feedback update received: ${feedback.length} items');
        if (mounted) {
          setState(() {
            _feedback = feedback.where((item) => item['user_profiles'] != null).toList();
            _calculateStats();
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFeedback() async {
    if (_businessId == null) {
      print('Cannot load feedback: businessId is null');
      return;
    }

    print('Loading feedback for business ID: $_businessId');

    try {
      final feedback = await _feedbackService.getFeedback(_businessId!);
      print('Successfully loaded ${feedback.length} feedback items');
      print('Feedback data: $feedback');
      
      if (mounted) {
        setState(() {
          _feedback = feedback.where((item) => item['user_profiles'] != null).toList();
          _calculateStats();
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feedback: $e')),
        );
      }
    }
  }

  void _calculateStats() {
    final stats = _feedbackService.getFeedbackStats(_feedback);
    setState(() {
      _averageRating = stats['averageRating'];
      _totalFeedback = stats['totalReviews'];
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeedback,
              child: Column(
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
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: const Center(
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
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _feedback.length,
                            itemBuilder: (context, index) {
                              final feedback = _feedback[index];
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
                                          backgroundColor: const Color(0xFF7B61FF),
                                          child: Text(
                                            _getInitials(feedback),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                _getDisplayName(feedback),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
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

  String _getDisplayName(Map<String, dynamic> feedback) {
    final userProfile = feedback['user_profiles'];
    if (userProfile == null) {
      return 'Anonymous';
    }
    
    final firstName = userProfile['first_name']?.toString() ?? '';
    final lastName = userProfile['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    if (fullName.isNotEmpty) {
      return fullName;
    } else if (userProfile['username'] != null && userProfile['username'].toString().isNotEmpty) {
      return userProfile['username'];
    } else if (userProfile['email'] != null && userProfile['email'].toString().isNotEmpty) {
      final email = userProfile['email'].toString();
      return email.split('@').first;
    } else {
      return 'Anonymous';
    }
  }

  String _getInitials(Map<String, dynamic> feedback) {
    final userProfile = feedback['user_profiles'];
    if (userProfile == null) {
      return 'A';
    }
    
    final firstName = userProfile['first_name']?.toString() ?? '';
    
    if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (userProfile['username'] != null && userProfile['username'].toString().isNotEmpty) {
      return userProfile['username'][0].toUpperCase();
    } else if (userProfile['email'] != null && userProfile['email'].toString().isNotEmpty) {
      return userProfile['email'][0].toUpperCase();
    } else {
      return 'A';
    }
  }


}