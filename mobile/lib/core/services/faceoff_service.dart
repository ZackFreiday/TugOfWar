import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/faceoff.dart';

class FaceOffService {
  static const String _baseUrl =
      'http://localhost:5018/api/FaceOffs';

  Future<List<FaceOff>> getFaceOffs() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final decodedBody = jsonDecode(response.body);

      if (decodedBody is! List) {
        throw Exception('Unexpected face-off response.');
      }

      return decodedBody
          .map(
            (item) => FaceOff.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception('Failed to load face-offs.');
  }
}