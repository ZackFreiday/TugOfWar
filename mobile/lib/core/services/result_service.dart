import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff_result.dart';
import 'auth_service.dart';

class ResultService {
  static const String _baseUrl =
      'http://localhost:5018/api/FaceOffs';

  final AuthService _authService = AuthService();

  Future<FaceOffResult> getResults(int faceOffId) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/$faceOffId/results'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return FaceOffResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_readError(response));
  }

  String _readError(http.Response response) {
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['detail']?.toString() ??
            decoded['message']?.toString() ??
            'Results could not be loaded.';
      }
    }

    return 'Results could not be loaded.';
  }
}