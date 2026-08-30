import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_response.dart';
import '../config/api_config.dart';

class SessionExpiredException
    implements Exception {
  const SessionExpiredException();

  @override
  String toString() {
    return 'Your session has expired. '
        'Please log in again.';
  }
}

class AuthService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/Auth';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static final StreamController<void>
      _sessionExpiredController =
      StreamController<void>.broadcast();

  static Stream<void> get sessionExpiredStream =>
      _sessionExpiredController.stream;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    return _handleAuthResponse(
      response,
    );
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    return _handleAuthResponse(
      response,
    );
  }

  Future<String?> getToken() {
    return _storage.read(
      key: 'jwt_token',
    );
  }

  Future<void> logout() {
    return _storage.delete(
      key: 'jwt_token',
    );
  }

  Future<void> handleUnauthorized() async {
    await logout();

    _sessionExpiredController.add(
      null,
    );

    throw const SessionExpiredException();
  }

  Future<AuthResponse> _handleAuthResponse(
    http.Response response,
  ) async {
    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      final decodedBody =
          jsonDecode(
        response.body,
      );

      if (decodedBody
          is Map<String, dynamic>) {
        body = decodedBody;
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final authResponse =
          AuthResponse.fromJson(
        body,
      );

      await _storage.write(
        key: 'jwt_token',
        value: authResponse.token,
      );

      return authResponse;
    }

    final message =
        body['detail']
                ?.toString() ??
            body['message']
                ?.toString() ??
            'Authentication failed.';

    throw Exception(
      message,
    );
  }
}