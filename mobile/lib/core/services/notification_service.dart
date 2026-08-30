import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/app_notification.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class NotificationService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/notifications';

  final AuthService _authService =
      AuthService();

  Future<List<AppNotification>>
      getNotifications() async {
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
          'Unexpected notification response.',
        );
      }

      return decoded
          .map(
            (item) =>
                AppNotification.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Notifications could not be loaded.',
      ),
    );
  }

  Future<int> getUnreadCount() async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/unread-count',
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
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return decoded['unreadCount']
              as int? ??
          0;
    }

    throw Exception(
      _readError(
        response,
        'Unread count could not be loaded.',
      ),
    );
  }

  Future<void> markAsRead(
    int notificationId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$notificationId/read',
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
          'Notification could not be marked as read.',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/read-all',
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
          'Notifications could not be marked as read.',
        ),
      );
    }
  }

  Future<void> deleteNotification(
    int notificationId,
  ) async {
    final token =
        await _getToken();

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/$notificationId',
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
          'Notification could not be deleted.',
        ),
      );
    }
  }

  Future<void>
      deleteAllNotifications() async {
    final token =
        await _getToken();

    final response = await http.delete(
      Uri.parse(_baseUrl),
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
          'Notifications could not be deleted.',
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