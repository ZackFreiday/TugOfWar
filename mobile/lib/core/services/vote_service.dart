import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class VoteService {
  static const String _baseUrl =
      'http://localhost:5018/api/faceoffs';

  final AuthService _authService = AuthService();

  Future<void> submitVote({
    required int faceOffId,
    required int chosenSide,
    required int coinBoostSupport,
  }) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/$faceOffId/votes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chosenSide': chosenSide,
        'coinBoostSupport': coinBoostSupport,
      }),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    final message =
        body['detail']?.toString() ??
        body['message']?.toString() ??
        'Vote could not be submitted.';

    throw Exception(message);
  }
}