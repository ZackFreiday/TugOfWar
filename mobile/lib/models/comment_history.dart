class CommentHistory {
  final int commentId;
  final int faceOffId;
  final String faceOffTitle;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;

  const CommentHistory({
    required this.commentId,
    required this.faceOffId,
    required this.faceOffTitle,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
  });

  factory CommentHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommentHistory(
      commentId:
          json['commentId'] as int,
      faceOffId:
          json['faceOffId'] as int,
      faceOffTitle:
          json['faceOffTitle'] as String,
      content:
          json['content'] as String,
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
          json['likeCount'] as int,
    );
  }
}