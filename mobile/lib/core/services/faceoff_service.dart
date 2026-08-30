import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class FaceOffService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/FaceOffs';

  final AuthService _authService =
      AuthService();

  Future<List<FaceOff>> getFaceOffs() async {
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
      final decodedBody =
          jsonDecode(response.body);

      if (decodedBody is! List) {
        throw Exception(
          'Unexpected face-off response.',
        );
      }

      return decodedBody
          .map(
            (item) =>
                FaceOff.fromJson(
              item
                  as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Failed to load face-offs.',
      ),
    );
  }

  Future<FaceOff> getFaceOffById(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/$faceOffId',
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
      return FaceOff.fromJson(
        jsonDecode(response.body)
            as Map<String, dynamic>,
      );
    }

    throw Exception(
      _readError(
        response,
        'Face-off could not be loaded.',
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