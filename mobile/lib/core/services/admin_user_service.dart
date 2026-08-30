import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/admin_user.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminUserService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/admin/users';

  final AuthService _authService =
      AuthService();

  Future<List<AdminUser>> getUsers() async {
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
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected users response.',
        );
      }

      return decoded
          .map(
            (item) => AdminUser.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Users could not be loaded.',
      ),
    );
  }

  Future<void> suspendUser(
    int userId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$userId/suspend',
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
          'The user could not be suspended.',
        ),
      );
    }
  }

  Future<void> unsuspendUser(
    int userId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$userId/unsuspend',
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
          'The user could not be unsuspended.',
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
        // The server response was not JSON.
      }
    }

    return fallback;
  }
}