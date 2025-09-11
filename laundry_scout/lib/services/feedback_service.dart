import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for storing feedback data
  final Map<String, List<Map<String, dynamic>>> _feedbackCache = {};
  final Map<String, dynamic> _subscriptions = {};
  final Map<String, Function> _listeners = {};

  /// Get feedback for a specific business
  Future<List<Map<String, dynamic>>> getFeedback(String businessId) async {
    try {
      if (_feedbackCache.containsKey(businessId)) {
        print('Using cached feedback for business: $businessId');
        return _feedbackCache[businessId]!;
      }

      print('Querying feedback table for business_id: $businessId');
      
      final response = await _supabase
          .from('feedback')
          .select('*')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      print('Query response: $response');
      final feedback = List<Map<String, dynamic>>.from(response);
      print('Found ${feedback.length} feedback items');
      
      // Manually fetch user profiles for each feedback item
      for (var feedbackItem in feedback) {
        final userId = feedbackItem['user_id'];
        if (userId != null) {
          try {
            final userProfile = await _supabase
                .from('user_profiles')
                .select('first_name, last_name, username, email')
                .eq('id', userId)
                .maybeSingle();
            
            feedbackItem['user_profiles'] = userProfile;
          } catch (e) {
            print('Error fetching user profile for user $userId: $e');
            feedbackItem['user_profiles'] = null;
          }
        }
      }
      
      _feedbackCache[businessId] = feedback;
      return feedback;
    } catch (e) {
      print('Error in getFeedback: $e');
      throw Exception('Failed to load feedback: $e');
    }
  }

  /// Get feedback statistics for a business
  Map<String, dynamic> getFeedbackStats(List<Map<String, dynamic>> feedback) {
    if (feedback.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }

    final totalReviews = feedback.length;
    final totalRating = feedback.fold(0.0, (sum, review) => sum + (review['rating'] ?? 0));
    final averageRating = totalRating / totalReviews;

    // Calculate rating distribution
    final ratingDistribution = [0, 0, 0, 0, 0];
    for (var review in feedback) {
      final rating = (review['rating'] ?? 0).toInt();
      if (rating >= 1 && rating <= 5) {
        ratingDistribution[rating - 1]++;
      }
    }

    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
    };
  }

  /// Subscribe to real-time feedback updates for a business
  void subscribeToFeedback(String businessId, Function(List<Map<String, dynamic>>) onUpdate) {
    print('🔄 Setting up real-time subscription for business: $businessId');
    
    // Remove existing subscription if any
    unsubscribeFromFeedback(businessId);

    _listeners[businessId] = onUpdate;

    final channel = _supabase
        .channel('feedback_$businessId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'feedback',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (payload) async {
            print('🔥 Real-time feedback INSERT detected for business: $businessId');
            print('📄 Payload: ${payload.newRecord}');
            await _refreshFeedbackData(businessId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'feedback',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (payload) async {
            print('🔥 Real-time feedback UPDATE detected for business: $businessId');
            print('📄 Payload: ${payload.newRecord}');
            await _refreshFeedbackData(businessId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'feedback',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (payload) async {
            print('🔥 Real-time feedback DELETE detected for business: $businessId');
            print('📄 Payload: ${payload.oldRecord}');
            await _refreshFeedbackData(businessId);
          },
        )
        .subscribe();

    print('✅ Real-time channel subscribed for business: $businessId');
    
    // Store the channel subscription
    _subscriptions[businessId] = channel;
  }

  /// Refresh feedback data and notify listeners
  Future<void> _refreshFeedbackData(String businessId) async {
    try {
      print('🔄 Refreshing feedback data for business: $businessId');
      
      final completeData = await _supabase
          .from('feedback')
          .select('*')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      
      final feedback = List<Map<String, dynamic>>.from(completeData);
      print('📊 Fetched ${feedback.length} feedback records from database');
      
      // Manually fetch user profiles for each feedback item
      for (var feedbackItem in feedback) {
        final userId = feedbackItem['user_id'];
        if (userId != null) {
          try {
            final userProfile = await _supabase
                .from('user_profiles')
                .select('first_name, last_name, username, email')
                .eq('id', userId)
                .maybeSingle();
            
            feedbackItem['user_profiles'] = userProfile;
          } catch (e) {
            print('Error fetching user profile for user $userId: $e');
            feedbackItem['user_profiles'] = null;
          }
        }
      }
      
      _feedbackCache[businessId] = feedback;
      
      // Notify all listeners for this business
      if (_listeners.containsKey(businessId)) {
        print('📢 Notifying listener with ${feedback.length} feedback items');
        _listeners[businessId]!(feedback);
      } else {
        print('⚠️ No listener found for business: $businessId');
      }
      
      print('✅ Feedback data refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing feedback data: $e');
    }
  }
  
  /// Unsubscribe from feedback updates
  void unsubscribeFromFeedback(String businessId) {
    if (_subscriptions.containsKey(businessId)) {
      final channel = _subscriptions[businessId];
      if (channel != null) {
        channel.unsubscribe();
      }
      _subscriptions.remove(businessId);
    }
    if (_listeners.containsKey(businessId)) {
      _listeners.remove(businessId);
    }
  }

  /// Add a new review
  Future<void> addReview({
    required String businessId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _supabase.from('feedback').insert({
        'business_id': businessId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Clear cache for this business to ensure fresh data is fetched
      _feedbackCache.remove(businessId);
      
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  /// Get business ID for the current user (business owner)
  Future<String?> getBusinessIdForOwner(String userId) async {
    try {
      print('Looking for business ID for user: $userId');
      final response = await _supabase
          .from('business_profiles')
          .select('id')
          .eq('id', userId)
          .single();
      
      final businessId = response['id'] as String?;
      print('Found business ID: $businessId');
      return businessId;
    } catch (e) {
      print('Error finding business ID for user $userId: $e');
      return null;
    }
  }

  /// Clear cache for a specific business
  void clearCache(String businessId) {
    _feedbackCache.remove(businessId);
  }

  /// Clear all cache
  void clearAllCache() {
    _feedbackCache.clear();
  }

  /// Dispose all subscriptions
  void dispose() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _listeners.clear();
    _feedbackCache.clear();
  }
}