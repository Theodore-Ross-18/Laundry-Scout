// lib/models/feedback_model.dart
class FeedbackModel {
  final String id;
  final String userId;
  final String businessId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final UserProfile? userProfile;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userProfile,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      businessId: json['business_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      userProfile: json['user_profiles'] != null
          ? UserProfile.fromJson(json['user_profiles'])
          : null,
    );
  }
}

class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;

  UserProfile({
    this.firstName,
    this.lastName,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImageUrl: json['profile_image_url'],
    );
  }
}
