class FaceOff {
  final int id;
  final String title;
  final String description;
  final String sideAName;
  final String sideBName;
  final DateTime startTime;
  final DateTime endTime;
  final int status;
  final bool isFeatured;

  const FaceOff({
    required this.id,
    required this.title,
    required this.description,
    required this.sideAName,
    required this.sideBName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isFeatured,
  });

  factory FaceOff.fromJson(Map<String, dynamic> json) {
    return FaceOff(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      sideAName: json['sideAName'] as String,
      sideBName: json['sideBName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as int,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  bool get isLive =>
      DateTime.now().toUtc().isAfter(startTime) &&
      DateTime.now().toUtc().isBefore(endTime) &&
      status == 2;
}