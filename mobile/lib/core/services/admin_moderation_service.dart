import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/comment_report.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class AdminModerationService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/admin/comment-reports';

  final AuthService _authService =
      AuthService();

  Future<List<CommentReport>>
      getReports() async {
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

    if (_isSuccessful(
      response.statusCode,
    )) {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! List) {
        throw Exception(
          'Unexpected moderation response.',
        );
      }

      return decoded
          .map(
            (item) =>
                CommentReport.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Reports could not be loaded.',
      ),
    );
  }

  Future<void> dismissReport(
    int reportId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$reportId/dismiss',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (!_isSuccessful(
      response.statusCode,
    )) {
      throw Exception(
        _readError(
          response,
          'The report could not be dismissed.',
        ),
      );
    }
  }

  Future<void> deleteReportedComment(
    int reportId,
  ) async {
    final token =
        await _getToken();

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/$reportId/comment',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    await _handleUnauthorized(
      response,
    );

    if (!_isSuccessful(
      response.statusCode,
    )) {
      throw Exception(
        _readError(
          response,
          'The reported comment could not be deleted.',
        ),
      );
    }
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
        // Response was not JSON.
      }
    }

    return fallback;
  }
}