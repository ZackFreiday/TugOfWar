import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff_result.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ResultService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/FaceOffs';

  final AuthService _authService =
      AuthService();

  Future<FaceOffResult> getResults(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/$faceOffId/results',
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
      return FaceOffResult.fromJson(
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
              'Results could not be loaded.';
        }
      } catch (_) {
        // The response was not JSON.
      }
    }

    return 'Results could not be loaded.';
  }
}