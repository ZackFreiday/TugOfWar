class FaceOffComment {
  final int id;
  final int faceOffId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool isLikedByCurrentUser;
  final int? chosenSide;

  const FaceOffComment({
    required this.id,
    required this.faceOffId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.isLikedByCurrentUser,
    required this.chosenSide,
  });

  factory FaceOffComment.fromJson(
    Map<String, dynamic> json,
  ) {
    return FaceOffComment(
      id: json['id'] as int,
      faceOffId: json['faceOffId'] as int,
      userId: json['userId'] as int,
      username:
          json['username'] as String? ?? '',
      content:
          json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(
                  json['updatedAt']
                      as String,
                ),
      likeCount:
          json['likeCount'] as int? ?? 0,
      isLikedByCurrentUser:
          json['isLikedByCurrentUser']
                  as bool? ??
              false,
      chosenSide:
          json['chosenSide'] as int?,
    );
  }
}