class AuthResponse {
  final String token;
  final int userId;
  final String username;
  final int coinBalance;

  const AuthResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.coinBalance,
  });

  factory AuthResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResponse(
      token: json['token'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      coinBalance: json['coinBalance'] as int,
    );
  }
}