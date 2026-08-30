import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class AdminFaceOffService {
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
      final decoded =
          jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception(
          'Unexpected face-off response.',
        );
      }

      return decoded
          .map(
            (item) => FaceOff.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      _readError(
        response,
        'Face-offs could not be loaded.',
      ),
    );
  }

  Future<FaceOff> createFaceOff({
    required String title,
    required String description,
    required int categoryId,
    required String sideAName,
    required String sideBName,
    required String? sideAImageUrl,
    required String? sideBImageUrl,
    required DateTime startTime,
    required DateTime endTime,
    required bool isFeatured,
  }) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
        'categoryId': categoryId,
        'sideAName': sideAName.trim(),
        'sideBName': sideBName.trim(),
        'sideAImageUrl':
            _cleanOptionalText(
          sideAImageUrl,
        ),
        'sideBImageUrl':
            _cleanOptionalText(
          sideBImageUrl,
        ),
        'startTime':
            startTime
                .toUtc()
                .toIso8601String(),
        'endTime':
            endTime
                .toUtc()
                .toIso8601String(),
        'isFeatured':
            isFeatured,
      }),
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
        'The face-off could not be created.',
      ),
    );
  }

  Future<FaceOff> updateFaceOff({
    required int faceOffId,
    required String title,
    required String description,
    required int categoryId,
    required String sideAName,
    required String sideBName,
    required String? sideAImageUrl,
    required String? sideBImageUrl,
    required DateTime startTime,
    required DateTime endTime,
    required bool isFeatured,
  }) async {
    final token =
        await _getToken();

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/$faceOffId',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
        'categoryId': categoryId,
        'sideAName': sideAName.trim(),
        'sideBName': sideBName.trim(),
        'sideAImageUrl':
            _cleanOptionalText(
          sideAImageUrl,
        ),
        'sideBImageUrl':
            _cleanOptionalText(
          sideBImageUrl,
        ),
        'startTime':
            startTime
                .toUtc()
                .toIso8601String(),
        'endTime':
            endTime
                .toUtc()
                .toIso8601String(),
        'isFeatured':
            isFeatured,
      }),
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
        'The face-off could not be updated.',
      ),
    );
  }

  Future<void> closeFaceOff(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/close',
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
          'The face-off could not be closed.',
        ),
      );
    }
  }

  Future<void> archiveFaceOff(
    int faceOffId,
  ) async {
    final token =
        await _getToken();

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/$faceOffId/archive',
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
          'The face-off could not be archived.',
        ),
      );
    }
  }

  String? _cleanOptionalText(
    String? value,
  ) {
    final trimmed =
        value?.trim();

    if (trimmed == null ||
        trimmed.isEmpty) {
      return null;
    }

    return trimmed;
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
    if (response.body.isEmpty) {
      return fallback;
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
            fallback;
      }
    } catch (_) {
      // The server response was not JSON.
    }

    return fallback;
  }
}