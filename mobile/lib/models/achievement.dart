class Achievement {
  final String code;
  final String name;
  final String description;
  final bool isUnlocked;
  final int currentProgress;
  final int requiredProgress;

  const Achievement({
    required this.code,
    required this.name,
    required this.description,
    required this.isUnlocked,
    required this.currentProgress,
    required this.requiredProgress,
  });

  factory Achievement.fromJson(
    Map<String, dynamic> json,
  ) {
    return Achievement(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description:
          json['description'] as String? ?? '',
      isUnlocked:
          json['isUnlocked'] as bool? ?? false,
      currentProgress:
          json['currentProgress'] as int? ?? 0,
      requiredProgress:
          json['requiredProgress'] as int? ?? 0,
    );
  }
}