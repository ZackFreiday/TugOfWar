class CoinTransactionHistory {
  final int id;
  final int amount;
  final int type;
  final String typeName;
  final int? faceOffId;
  final String? faceOffTitle;
  final DateTime createdAt;

  const CoinTransactionHistory({
    required this.id,
    required this.amount,
    required this.type,
    required this.typeName,
    required this.faceOffId,
    required this.faceOffTitle,
    required this.createdAt,
  });

  factory CoinTransactionHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return CoinTransactionHistory(
      id: json['id'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      typeName:
          json['typeName'] as String? ?? '',
      faceOffId:
          json['faceOffId'] as int?,
      faceOffTitle:
          json['faceOffTitle'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
    );
  }
}