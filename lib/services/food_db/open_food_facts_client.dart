import 'package:dio/dio.dart';
import '../../models/macros.dart';

class OpenFoodFactsClient {
  final Dio _dio;

  OpenFoodFactsClient({Dio? dio}) : _dio = dio ?? Dio();

  Future<PerHundred?> search(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'json': '1',
          'page_size': '1',
        },
      );

      final data = response.data;
      if (data == null) return null;

      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return null;

      final product = products[0] as Map<String, dynamic>?;
      if (product == null) return null;

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) return null;

      final kcal = _toDouble(nutriments['energy-kcal_100g']);
      final protein = _toDouble(nutriments['proteins_100g']);
      final carb = _toDouble(nutriments['carbohydrates_100g']);
      final fat = _toDouble(nutriments['fat_100g']);
      final fibre = _toDouble(nutriments['fiber_100g'] ?? nutriments['fiber-100g']);
      final sodium = _toDouble(nutriments['sodium_100g']);

      if (kcal == null || protein == null || carb == null || fat == null) {
        return null;
      }

      return PerHundred(kcal: kcal, protein: protein, carb: carb, fat: fat, fibre: fibre, sodium: sodium);
    } catch (_) {
      return null;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
