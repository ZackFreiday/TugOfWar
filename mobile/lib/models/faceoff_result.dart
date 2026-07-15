class FaceOffResult {
  final int faceOffId;
  final String title;
  final String sideAName;
  final String sideBName;
  final int sideAVotes;
  final int sideBVotes;
  final int sideASupport;
  final int sideBSupport;
  final int totalParticipants;
  final double sideAPercentage;
  final double sideBPercentage;
  final String? userSupportedSide;

  const FaceOffResult({
    required this.faceOffId,
    required this.title,
    required this.sideAName,
    required this.sideBName,
    required this.sideAVotes,
    required this.sideBVotes,
    required this.sideASupport,
    required this.sideBSupport,
    required this.totalParticipants,
    required this.sideAPercentage,
    required this.sideBPercentage,
    required this.userSupportedSide,
  });

  factory FaceOffResult.fromJson(Map<String, dynamic> json) {
    return FaceOffResult(
      faceOffId: json['faceOffId'] as int,
      title: json['title'] as String? ?? '',
      sideAName: json['sideAName'] as String? ?? '',
      sideBName: json['sideBName'] as String? ?? '',
      sideAVotes: json['sideAVotes'] as int? ?? 0,
      sideBVotes: json['sideBVotes'] as int? ?? 0,
      sideASupport: json['sideASupport'] as int? ?? 0,
      sideBSupport: json['sideBSupport'] as int? ?? 0,
      totalParticipants: json['totalParticipants'] as int? ?? 0,
      sideAPercentage:
          (json['sideAPercentage'] as num?)?.toDouble() ?? 0,
      sideBPercentage:
          (json['sideBPercentage'] as num?)?.toDouble() ?? 0,
      userSupportedSide: json['userSupportedSide'] as String?,
    );
  }
}