import 'package:dio/dio.dart';
import '../../models/macros.dart';

class UsdaCandidate {
  final String description;
  final PerHundred perHundred;
  const UsdaCandidate({required this.description, required this.perHundred});
}

class UsdaClient {
  final Dio _dio;
  final String apiKey;

  UsdaClient({required this.apiKey, Dio? dio}) : _dio = dio ?? Dio();

  Future<PerHundred?> search(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.nal.usda.gov/fdc/v1/foods/search',
        queryParameters: {
          'api_key': apiKey,
          'query': query,
          // Prefer generic whole-food datasets (complete per-100g profiles)
          // over Branded products, which often miss a nutrient or report per
          // serving. Fetch several and use the first complete one.
          'dataType': 'Foundation,SR Legacy,Survey (FNDDS)',
          'pageSize': '10',
        },
      );

      final data = response.data;
      if (data == null) return null;

      final foods = data['foods'] as List<dynamic>?;
      if (foods == null || foods.isEmpty) return null;

      for (final f in foods) {
        final per = _parseFood(f as Map<String, dynamic>?);
        if (per != null) return per;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Up to ~8 parsed candidates for autocomplete; [] on error/missing key. Each
  /// candidate already has per-100g macros so selecting one needs no 2nd call.
  Future<List<UsdaCandidate>> searchCandidates(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.nal.usda.gov/fdc/v1/foods/search',
        queryParameters: {'api_key': apiKey, 'query': query, 'dataType': 'Foundation,SR Legacy,Survey (FNDDS)', 'pageSize': '8'},
      );
      final foods = (response.data?['foods'] as List<dynamic>?) ?? [];
      final out = <UsdaCandidate>[];
      for (final f in foods) {
        final food = f as Map<String, dynamic>?;
        final desc = (food?['description'] as String?) ?? '';
        final per = _parseFood(food);
        if (per != null && desc.isNotEmpty) out.add(UsdaCandidate(description: desc, perHundred: per));
      }
      return out;
    } catch (_) { return []; }
  }

  /// Parses one search-result food into per-100g macros, or null if it doesn't
  /// carry all four nutrients. Energy prefers the KCAL entry (USDA also lists
  /// energy in kJ under the same name).
  PerHundred? _parseFood(Map<String, dynamic>? food) {
    if (food == null) return null;
    final nutrients = food['foodNutrients'] as List<dynamic>?;
    if (nutrients == null) return null;

    double? kcal;
    double? kcalFallback;
    double? protein;
    double? carb;
    double? fat;
    double? fibre;
    double? sodium;

    for (final n in nutrients) {
      final nutrient = n as Map<String, dynamic>;
      final name = (nutrient['nutrientName'] as String?)?.toLowerCase() ?? '';
      final unit = (nutrient['unitName'] as String?)?.toUpperCase() ?? '';
      final value = _toDouble(nutrient['value']);
      if (value == null) continue;

      if (name == 'energy') {
        if (unit == 'KCAL') {
          kcal = value; // definitive
        } else {
          kcalFallback ??= value; // kJ or unspecified — only if no kcal found
        }
      } else if (name == 'protein') {
        protein = value;
      } else if (name == 'carbohydrate, by difference') {
        carb = value;
      } else if (name == 'total lipid (fat)') {
        fat = value;
      } else if (name.contains('fiber')) {
        fibre = value;
      } else if (name == 'sodium, na') {
        sodium = value;
      }
    }

    kcal ??= kcalFallback;
    if (kcal == null || protein == null || carb == null || fat == null) {
      return null;
    }
    return PerHundred(kcal: kcal, protein: protein, carb: carb, fat: fat, fibre: fibre, sodium: sodium);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
