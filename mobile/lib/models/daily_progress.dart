class DailyProgress {
  final int votesToday;
  final int votesRequired;
  final int rewardCoins;
  final bool rewardClaimed;

  const DailyProgress({
    required this.votesToday,
    required this.votesRequired,
    required this.rewardCoins,
    required this.rewardClaimed,
  });

  factory DailyProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyProgress(
      votesToday:
          json['votesToday'] as int? ?? 0,
      votesRequired:
          json['votesRequired'] as int? ?? 0,
      rewardCoins:
          json['rewardCoins'] as int? ?? 0,
      rewardClaimed:
          json['rewardClaimed'] as bool? ?? false,
    );
  }
}