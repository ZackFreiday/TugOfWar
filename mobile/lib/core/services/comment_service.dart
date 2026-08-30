import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff_comment.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class CommentService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/faceoffs';

  final AuthService _authService =
      AuthService();

  Future<List<FaceOffComment>> getComments(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected comments response.',
        );
      }

      return decoded
          .map(
            (item) =>
                FaceOffComment.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
      ),
    );
  }

  Future<FaceOffComment> createComment({
    required int faceOffId,
    required String content,
  }) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content.trim(),
      }),
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      return FaceOffComment.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
      ),
    );
  }

  Future<FaceOffComment> updateComment({
    required int faceOffId,
    required int commentId,
    required String content,
  }) async {
    final token =
        await _getToken();

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments/$commentId',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content.trim(),
      }),
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      return FaceOffComment.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
      ),
    );
  }

  Future<void> deleteComment({
    required int faceOffId,
    required int commentId,
  }) async {
    final token =
        await _getToken();

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments/$commentId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      return;
    }

    throw Exception(
      _readError(
        response,
      ),
    );
  }

  Future<FaceOffComment> toggleLike({
    required int faceOffId,
    required int commentId,
  }) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments/$commentId/like',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      return FaceOffComment.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
      ),
    );
  }

  Future<void> reportComment({
    required int faceOffId,
    required int commentId,
    required String reason,
  }) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/comments/$commentId/report',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reason': reason.trim(),
      }),
    );

    await _handleUnauthorized(
      response,
    );

    if (_isSuccessful(
      response.statusCode,
    )) {
      return;
    }

    throw Exception(
      _readError(
        response,
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

  bool _isSuccessful(
    int statusCode,
  ) {
    return statusCode >= 200 &&
        statusCode < 300;
  }

  String _readError(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return 'Comment request failed.';
    }

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
            'Comment request failed.';
      }
    } catch (_) {
      // The server response was not JSON.
    }

    return 'Comment request failed.';
  }
}