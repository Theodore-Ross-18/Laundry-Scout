import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/feedback_service.dart';

class UserFeedbackScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const UserFeedbackScreen({
    Key? key,
    required this.businessId,
    required this.businessName,
  }) : super(key: key);

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
    _feedbackService.subscribeToFeedback(widget.businessId, (data) {
      if (mounted) {
        setState(() => _feedbackList = data);
      }
    });
  }

  Future<void> _loadFeedback() async {
    try {
      final data = await _feedbackService.getFeedback(widget.businessId);
      if (mounted) {
        setState(() {
          _feedbackList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('❌ Failed to load feedback: $e');
    }
  }

  @override
  void dispose() {
    _feedbackService.unsubscribeFromFeedback(widget.businessId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Reviews'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedbackList.isEmpty
              ? const Center(child: Text('No reviews yet.'))
              : RefreshIndicator(
                  onRefresh: _loadFeedback,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _feedbackList.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbackList[index];
                      final profile = feedback['user_profiles'];

                      final userName = [
                        profile?['first_name'] ?? '',
                        profile?['last_name'] ?? ''
                      ].where((e) => e.isNotEmpty).join(' ');
                      final displayName = userName.isEmpty
                          ? (profile?['email'] ?? 'Anonymous')
                          : userName;

                      final comment = feedback['comment'] ?? '';
                      final rating = (feedback['rating'] ?? 0).toInt();

                      String createdAt = '';
                      try {
                        createdAt = DateFormat('MMM d, yyyy').format(
                          DateTime.parse(feedback['created_at'] ??
                              DateTime.now().toString()),
                        );
                      } catch (_) {
                        createdAt = 'Unknown date';
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1.5,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade200,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              if (comment.isNotEmpty)
                                Text(
                                  comment,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                createdAt,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
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
    );
  }
}
