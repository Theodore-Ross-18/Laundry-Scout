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
  final FeedbackService _feedbackService = FeedbackService();

  List<Map<String, dynamic>> _feedback = [];
  bool _isLoading = true;
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await _loadFeedback();

      // ✅ Real-time subscription
      _feedbackService.subscribeToFeedback(_businessId!, (feedback) {
        if (mounted) {
          setState(() {
            _feedback = feedback.where((item) => item['user_profiles'] != null).toList();
            _calculateStats();
          });
        }
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fetch all feedback
  Future<void> _loadFeedback() async {
    if (_businessId == null) return;

    try {
      final feedback = await _feedbackService.getFeedback(_businessId!);
      if (mounted) {
        setState(() {
          _feedback = feedback.where((item) => item['user_profiles'] != null).toList();
          _calculateStats();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feedback: $e')),
        );
      }
    }
  }

  /// Calculate average + total
  void _calculateStats() {
    final stats = _feedbackService.getFeedbackStats(_feedback);
    _averageRating = stats['averageRating'];
    _totalFeedback = stats['totalReviews'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text(
          'Customer Feedback',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
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
                  _buildStatsHeader(),
                  Expanded(
                    child: _feedback.isEmpty
                        ? _buildEmptyState()
                        : _buildFeedbackList(),
                  ),
                ],
              ),
            ),
    );
  }

  /// Stats summary header (polished style)
  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatBlock(
            value: _averageRating.toStringAsFixed(1),
            label: 'Avg. Rating',
            stars: _averageRating,
          ),
          Container(height: 60, width: 1, color: Colors.grey[300]),
          _buildStatBlock(
            value: _totalFeedback.toString(),
            label: 'Reviews',
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required String value,
    required String label,
    double stars = 0.0,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A35E3),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        if (stars > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                Icons.star_rounded,
                size: 20,
                color: index < stars ? Colors.orange : Colors.grey[300],
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No feedback yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Customer feedback will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _feedback.length,
      itemBuilder: (context, index) {
        final feedback = _feedback[index];
        final rating = (feedback['rating'] as num).toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User + Rating Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF5A35E3),
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
                        const SizedBox(height: 2),
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
                  _buildRatingStars(rating),
                ],
              ),
              if ((feedback['comment'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  feedback['comment'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Rating stars with half support
  Widget _buildRatingStars(double rating) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (starIndex) {
            if (rating >= starIndex + 1) {
              return const Icon(Icons.star_rounded, size: 18, color: Colors.orange);
            } else if (rating > starIndex && rating < starIndex + 1) {
              return const Icon(Icons.star_half_rounded, size: 18, color: Colors.orange);
            } else {
              return Icon(Icons.star_rounded, size: 18, color: Colors.grey[300]);
            }
          }),
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// Format timestamp
  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  /// Display name logic
  String _getDisplayName(Map<String, dynamic> feedback) {
    final userProfile = feedback['user_profiles'];
    if (userProfile == null) return 'Anonymous';

    final firstName = userProfile['first_name']?.toString() ?? '';
    final lastName = userProfile['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if ((userProfile['username'] ?? '').toString().isNotEmpty) {
      return userProfile['username'];
    }
    if ((userProfile['email'] ?? '').toString().isNotEmpty) {
      return userProfile['email'].toString().split('@').first;
    }
    return 'Anonymous';
  }

  /// Avatar initials
  String _getInitials(Map<String, dynamic> feedback) {
    final userProfile = feedback['user_profiles'];
    if (userProfile == null) return 'A';

    final firstName = userProfile['first_name']?.toString() ?? '';
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();

    if ((userProfile['username'] ?? '').toString().isNotEmpty) {
      return userProfile['username'][0].toUpperCase();
    }
    if ((userProfile['email'] ?? '').toString().isNotEmpty) {
      return userProfile['email'][0].toUpperCase();
    }
    return 'A';
  }
}
