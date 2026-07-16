import 'package:dio/dio.dart';
import '../../models/macros.dart';

class OpenFoodFactsClient {
  final Dio _dio;

  OpenFoodFactsClient({Dio? dio}) : _dio = dio ?? Dio();

  Future<PerHundred?> search(String query) async {
    final food = await searchFood(query);
    return food?.perHundred;
  }

  /// Looks up a product while preserving a label-provided serving basis.
  ///
  /// A count basis is useful even without a physical gram weight: it lets a
  /// user log the label's stated nutrition for one stick/serving without us
  /// inventing a gram conversion.
  Future<FoodMacros?> searchFood(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {'search_terms': query, 'json': '1', 'page_size': '1'},
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
      final fibre = _toDouble(
        nutriments['fiber_100g'] ?? nutriments['fiber-100g'],
      );
      final sodium = _toDouble(nutriments['sodium_100g']);

      if (kcal == null || protein == null || carb == null || fat == null) {
        return null;
      }

      final perHundred = PerHundred(
        kcal: kcal,
        protein: protein,
        carb: carb,
        fat: fat,
        fibre: fibre,
        sodium: sodium,
      );
      final servingSize = product['serving_size'];
      final grams = _servingGrams(servingSize);
      return FoodMacros(
        name: (product['product_name'] as String?)?.trim().isNotEmpty == true
            ? (product['product_name'] as String).trim()
            : query,
        perHundred: perHundred,
        source: MacroSource.off,
        isEstimate: false,
        basis: _servingBasis(nutriments, perHundred, grams, servingSize),
        gramsPerPiece: grams,
      );
    } catch (_) {
      return null;
    }
  }

  NutritionBasis? _servingBasis(
    Map<String, dynamic> nutriments,
    PerHundred perHundred,
    double? grams,
    dynamic servingSize,
  ) {
    final kcal = _toDouble(nutriments['energy-kcal_serving']);
    final protein = _toDouble(nutriments['proteins_serving']);
    final carb = _toDouble(nutriments['carbohydrates_serving']);
    final fat = _toDouble(nutriments['fat_serving']);
    final macros =
        kcal != null && protein != null && carb != null && fat != null
        ? MacroValues(
            kcal: kcal,
            protein: protein,
            carb: carb,
            fat: fat,
            fibre: _toDouble(
              nutriments['fiber_serving'] ?? nutriments['fiber-serving'],
            ),
          )
        // Per-100 g values can be scaled only when the label explicitly
        // publishes a gram serving size.
        : grams == null
        ? null
        : MacroValues(
            kcal: perHundred.kcal * grams / 100,
            protein: perHundred.protein * grams / 100,
            carb: perHundred.carb * grams / 100,
            fat: perHundred.fat * grams / 100,
            fibre: perHundred.fibre == null
                ? null
                : perHundred.fibre! * grams / 100,
          );
    if (macros == null) return null;
    // Preserve a label's explicit count unit. "1 stick" must stay a stick;
    // reducing it to a generic serving makes it unusable when logging sticks.
    final countBasis = _countServingBasis(servingSize);
    return NutritionBasis(
      quantity: countBasis?.quantity ?? 1,
      unit: countBasis?.unit ?? 'serving',
      macros: macros,
    );
  }

  _CountBasis? _countServingBasis(dynamic raw) {
    if (raw is! String) return null;
    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(piece|pieces|slice|slices|stick|sticks|item|items|serving|servings)\b',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return null;
    final quantity = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (quantity == null || !quantity.isFinite || quantity <= 0) return null;
    final rawUnit = match.group(2)!.toLowerCase();
    final unit = switch (rawUnit) {
      'pieces' => 'piece',
      'slices' => 'slice',
      'sticks' => 'stick',
      'items' => 'item',
      'servings' => 'serving',
      _ => rawUnit,
    };
    return _CountBasis(quantity, unit);
  }

  /// Recognises only a literal gram value (for example "1 stick (2 g)").
  /// A bare "1 stick" remains physically unknown.
  double? _servingGrams(dynamic raw) {
    if (raw is! String) return null;
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*g\b',
      caseSensitive: false,
    ).allMatches(raw);
    if (matches.isEmpty) return null;
    final value = double.tryParse(matches.last.group(1)!.replaceAll(',', '.'));
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _CountBasis {
  final double quantity;
  final String unit;
  const _CountBasis(this.quantity, this.unit);
}
