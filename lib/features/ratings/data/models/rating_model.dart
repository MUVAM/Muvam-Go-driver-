class RatingResponse {
  final List<Rating> ratings;

  RatingResponse({required this.ratings});

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      ratings: (json['ratings'] as List<dynamic>?)
              ?.map((r) => Rating.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class Rating {
  final int id;
  final String createdAt;
  final int rideId;
  final int raterId;
  final int ratedId;
  final String raterType;
  final int score;
  final String comment;

  Rating({
    required this.id,
    required this.createdAt,
    required this.rideId,
    required this.raterId,
    required this.ratedId,
    required this.raterType,
    required this.score,
    required this.comment,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['ID'] ?? 0,
      createdAt: json['CreatedAt'] ?? '',
      rideId: json['ride_id'] ?? 0,
      raterId: json['rater_id'] ?? 0,
      ratedId: json['rated_id'] ?? 0,
      raterType: json['rater_type'] ?? '',
      score: json['score'] ?? 0,
      comment: json['comment'] ?? '',
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = DateTime.parse(createdAt);
    final difference = now.difference(created);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
