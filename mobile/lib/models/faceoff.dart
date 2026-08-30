class FaceOff {
  final int id;
  final String title;
  final String description;
  final String sideAName;
  final String sideBName;
  final String? sideAImageUrl;
  final String? sideBImageUrl;
  final DateTime startTime;
  final DateTime endTime;
  final int status;
  final bool isFeatured;
  final int categoryId;

  final String? winningSide;
  final bool? isTie;
  final double? sideAPercentage;
  final double? sideBPercentage;

  const FaceOff({
    required this.id,
    required this.title,
    required this.description,
    required this.sideAName,
    required this.sideBName,
    required this.sideAImageUrl,
    required this.sideBImageUrl,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isFeatured,
    required this.categoryId,
    required this.winningSide,
    required this.isTie,
    required this.sideAPercentage,
    required this.sideBPercentage,
  });

  factory FaceOff.fromJson(
    Map<String, dynamic> json,
  ) {
    return FaceOff(
      id: json['id'] as int,
      title: json['title'] as String,
      description:
          json['description'] as String? ?? '',
      sideAName:
          json['sideAName'] as String,
      sideBName:
          json['sideBName'] as String,
      sideAImageUrl:
          json['sideAImageUrl'] as String?,
      sideBImageUrl:
          json['sideBImageUrl'] as String?,
      startTime: DateTime.parse(
        json['startTime'] as String,
      ),
      endTime: DateTime.parse(
        json['endTime'] as String,
      ),
      status:
          json['status'] as int,
      isFeatured:
          json['isFeatured'] as bool? ?? false,
      categoryId:
          json['categoryId'] as int,
      winningSide:
          json['winningSide'] as String?,
      isTie:
          json['isTie'] as bool?,
      sideAPercentage:
          (json['sideAPercentage'] as num?)
              ?.toDouble(),
      sideBPercentage:
          (json['sideBPercentage'] as num?)
              ?.toDouble(),
    );
  }

  bool get isLive =>
      DateTime.now()
          .toUtc()
          .isAfter(startTime) &&
      DateTime.now()
          .toUtc()
          .isBefore(endTime) &&
      status == 2;

  bool get hasFinalResult =>
      isTie != null &&
      sideAPercentage != null &&
      sideBPercentage != null;

  String? get winningSideName {
    if (isTie == true) {
      return null;
    }

    if (winningSide == 'A') {
      return sideAName;
    }

    if (winningSide == 'B') {
      return sideBName;
    }

    return null;
  }
}