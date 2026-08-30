class VoteHistory {
  final int faceOffId;
  final String faceOffTitle;
  final String sideAName;
  final String sideBName;
  final int chosenSide;
  final int coinBoostSupport;
  final DateTime votedAt;
  final DateTime startTime;
  final DateTime endTime;
  final int status;

  const VoteHistory({
    required this.faceOffId,
    required this.faceOffTitle,
    required this.sideAName,
    required this.sideBName,
    required this.chosenSide,
    required this.coinBoostSupport,
    required this.votedAt,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory VoteHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return VoteHistory(
      faceOffId: json['faceOffId'] as int,
      faceOffTitle:
          json['faceOffTitle'] as String? ?? '',
      sideAName:
          json['sideAName'] as String? ?? '',
      sideBName:
          json['sideBName'] as String? ?? '',
      chosenSide:
          json['chosenSide'] as int? ?? 0,
      coinBoostSupport:
          json['coinBoostSupport'] as int? ?? 0,
      votedAt: DateTime.parse(
        json['votedAt'] as String,
      ),
      startTime: DateTime.parse(
        json['startTime'] as String,
      ),
      endTime: DateTime.parse(
        json['endTime'] as String,
      ),
      status:
          json['status'] as int? ?? 0,
    );
  }
}