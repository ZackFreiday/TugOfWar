import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  static const String _baseUrl =
      'http://localhost:5018/api/profile';

  final AuthService _authService = AuthService();

  Future<Profile> getProfile() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Profile.fromJson(
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
            'Profile could not be loaded.';
      }
    }

    return 'Profile could not be loaded.';
  }

  Future<Profile> updateProfile({
  required String username,
  required String? bio,
  required String? country,
}) async {
  final token = await _authService.getToken();

  if (token == null || token.isEmpty) {
    throw Exception('You are not logged in.');
  }

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
    }),
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return Profile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  throw Exception(_readError(response));
}
}