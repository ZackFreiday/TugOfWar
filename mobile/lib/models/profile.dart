class Profile {
  final int id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final String? country;
  final int coinBalance;
  final DateTime createdAt;
  final int faceOffsParticipated;
  final int commentsCreated;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.profileImageUrl,
    required this.bio,
    required this.country,
    required this.coinBalance,
    required this.createdAt,
    required this.faceOffsParticipated,
    required this.commentsCreated,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
      coinBalance: json['coinBalance'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      faceOffsParticipated:
          json['faceOffsParticipated'] as int? ?? 0,
      commentsCreated: json['commentsCreated'] as int? ?? 0,
    );
  }
}