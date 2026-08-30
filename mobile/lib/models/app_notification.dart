class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? faceOffId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.faceOffId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? '',
      faceOffId: json['faceOffId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
    );
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      faceOffId: faceOffId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}