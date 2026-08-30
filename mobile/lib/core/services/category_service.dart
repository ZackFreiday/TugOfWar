import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/category.dart';
import '../config/api_config.dart';

class CategoryService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/Categories';

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final decodedBody =
          jsonDecode(response.body);

      if (decodedBody is! List) {
        throw Exception(
          'Unexpected category response.',
        );
      }

      return decodedBody
          .map(
            (item) => Category.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load categories.',
    );
  }
}