class AdminUser {
  final int id;
  final String username;
  final String email;
  final int coinBalance;
  final String? country;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isSuspended;
  final bool isAdmin;

  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.coinBalance,
    required this.country,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isSuspended,
    required this.isAdmin,
  });

  factory AdminUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminUser(
      id: json['id'] as int,
      username:
          json['username'] as String? ?? '',
      email:
          json['email'] as String? ?? '',
      coinBalance:
          json['coinBalance'] as int? ?? 0,
      country:
          json['country'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      lastLoginAt:
          json['lastLoginAt'] == null
              ? null
              : DateTime.parse(
                  json['lastLoginAt']
                      as String,
                ),
      isSuspended:
          json['isSuspended'] as bool? ??
              false,
      isAdmin:
          json['isAdmin'] as bool? ?? false,
    );
  }
}