import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../config/api_config.dart';

class SubmitVoteResult {
  final int voteId;
  final int faceOffId;
  final int chosenSide;
  final int coinBoostSupport;
  final int votesToday;
  final int votesRequired;
  final bool dailyRewardEarned;
  final int dailyRewardCoins;
  final int coinBalance;

  const SubmitVoteResult({
    required this.voteId,
    required this.faceOffId,
    required this.chosenSide,
    required this.coinBoostSupport,
    required this.votesToday,
    required this.votesRequired,
    required this.dailyRewardEarned,
    required this.dailyRewardCoins,
    required this.coinBalance,
  });

  factory SubmitVoteResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubmitVoteResult(
      voteId:
          json['voteId'] as int? ?? 0,
      faceOffId:
          json['faceOffId'] as int? ?? 0,
      chosenSide:
          json['chosenSide'] as int? ?? 0,
      coinBoostSupport:
          json['coinBoostSupport'] as int? ?? 0,
      votesToday:
          json['votesToday'] as int? ?? 0,
      votesRequired:
          json['votesRequired'] as int? ?? 0,
      dailyRewardEarned:
          json['dailyRewardEarned']
                  as bool? ??
              false,
      dailyRewardCoins:
          json['dailyRewardCoins'] as int? ?? 0,
      coinBalance:
          json['coinBalance'] as int? ?? 0,
    );
  }
}

class VoteService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/faceoffs';

  final AuthService _authService =
      AuthService();

  Future<SubmitVoteResult> submitVote({
    required int faceOffId,
    required int chosenSide,
    required int coinBoostSupport,
  }) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/votes',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chosenSide': chosenSide,
        'coinBoostSupport':
            coinBoostSupport,
      }),
    );

    await _handleUnauthorized(
      response,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return SubmitVoteResult.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
        'Vote could not be submitted.',
      ),
    );
  }

  Future<Map<String, dynamic>> getMyVote(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/$faceOffId/votes/me',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return jsonDecode(
        response.body,
      ) as Map<String, dynamic>;
    }

    throw Exception(
      _readError(
        response,
        'Could not load your vote.',
      ),
    );
  }

  Future<String> _getToken() async {
    final token =
        await _authService.getToken();

    if (token == null ||
        token.isEmpty) {
      await _authService
          .handleUnauthorized();

      throw const SessionExpiredException();
    }

    return token;
  }

  Future<void> _handleUnauthorized(
    http.Response response,
  ) async {
    if (response.statusCode == 401) {
      await _authService
          .handleUnauthorized();
    }
  }

  String _readError(
    http.Response response,
    String fallback,
  ) {
    if (response.body.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded
            is Map<String, dynamic>) {
          return decoded['detail']
                  ?.toString() ??
              decoded['message']
                  ?.toString() ??
              decoded['title']
                  ?.toString() ??
              fallback;
        }
      } catch (_) {
        // The response was not JSON.
      }
    }

    return fallback;
  }
}