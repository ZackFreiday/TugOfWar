import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/achievement.dart';
import '../../models/coin_transaction_history.dart';
import '../../models/comment_history.dart';
import '../../models/daily_progress.dart';
import '../../models/profile.dart';
import '../../models/vote_history.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ProfileService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/profile';

  final AuthService _authService =
      AuthService();

  Future<Profile> getProfile() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(_baseUrl),
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
      return Profile.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
        'Profile could not be loaded.',
      ),
    );
  }

  Future<Profile> updateProfile({
    required String username,
    required String? bio,
    required String? country,
    required String? profileImageUrl,
  }) async {
    final token =
        await _getToken();

    final response = await http.put(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': username.trim(),
        'bio': bio?.trim(),
        'country': country?.trim(),
        'profileImageUrl':
            profileImageUrl?.trim(),
      }),
    );

    await _handleUnauthorized(
      response,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Profile.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
        'Profile could not be updated.',
      ),
    );
  }

  Future<Profile> uploadProfileImage(
    XFile image,
  ) async {
    final token =
        await _getToken();

    final bytes =
        await image.readAsBytes();

    final request =
        http.MultipartRequest(
      'POST',
      Uri.parse(
        '$_baseUrl/image',
      ),
    );

    request.headers[
        'Authorization'] =
        'Bearer $token';

    request.headers[
        'Accept'] =
        'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    await _handleUnauthorized(
      response,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Unexpected profile image response.',
        );
      }

      final profileJson =
          decoded['profile'];

      if (profileJson
          is! Map<String, dynamic>) {
        throw Exception(
          'Unexpected profile image response.',
        );
      }

      return Profile.fromJson(
        profileJson,
      );
    }

    throw Exception(
      _readError(
        response,
        'Profile image could not be uploaded.',
      ),
    );
  }

  Future<Profile>
      deleteProfileImage() async {
    final token =
        await _getToken();

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/image',
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
      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Unexpected profile image response.',
        );
      }

      return Profile.fromJson(
        decoded,
      );
    }

    throw Exception(
      _readError(
        response,
        'Profile image could not be removed.',
      ),
    );
  }

  Future<List<VoteHistory>>
      getVoteHistory() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/votes',
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
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected vote history response.',
        );
      }

      return decoded
          .map(
            (item) =>
                VoteHistory.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Vote history could not be loaded.',
      ),
    );
  }

  Future<List<CommentHistory>>
      getCommentHistory() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/comments',
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
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected comment history response.',
        );
      }

      return decoded
          .map(
            (item) =>
                CommentHistory.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Comment history could not be loaded.',
      ),
    );
  }

  Future<List<Achievement>>
      getAchievements() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/achievements',
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
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected achievements response.',
        );
      }

      return decoded
          .map(
            (item) =>
                Achievement.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Achievements could not be loaded.',
      ),
    );
  }

  Future<DailyProgress>
      getDailyProgress() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/daily-progress',
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
      return DailyProgress.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
        'Daily progress could not be loaded.',
      ),
    );
  }

  Future<List<CoinTransactionHistory>>
      getCoinTransactions() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/coin-transactions',
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
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected coin transaction response.',
        );
      }

      return decoded
          .map(
            (item) =>
                CoinTransactionHistory.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Coin history could not be loaded.',
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