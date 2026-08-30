class CommentReport {
  final int id;
  final int commentId;
  final int faceOffId;
  final String faceOffTitle;
  final int commentUserId;
  final String commentUsername;
  final String commentContent;
  final int reporterUserId;
  final String reporterUsername;
  final String reason;
  final DateTime createdAt;
  final bool isResolved;

  const CommentReport({
    required this.id,
    required this.commentId,
    required this.faceOffId,
    required this.faceOffTitle,
    required this.commentUserId,
    required this.commentUsername,
    required this.commentContent,
    required this.reporterUserId,
    required this.reporterUsername,
    required this.reason,
    required this.createdAt,
    required this.isResolved,
  });

  factory CommentReport.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommentReport(
      id: json['id'] as int,
      commentId: json['commentId'] as int,
      faceOffId: json['faceOffId'] as int? ?? 0,
      faceOffTitle:
          json['faceOffTitle'] as String? ?? '',
      commentUserId:
          json['commentUserId'] as int? ?? 0,
      commentUsername:
          json['commentUsername'] as String? ?? '',
      commentContent:
          json['commentContent'] as String? ?? '',
      reporterUserId:
          json['reporterUserId'] as int,
      reporterUsername:
          json['reporterUsername'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      isResolved:
          json['isResolved'] as bool? ?? false,
    );
  }
}