import '../data/repositories/food_cache_repository.dart';
import '../models/macros.dart';
import 'custom_food_basis.dart';

/// Persists remembered foods without changing the portion the user entered.
///
/// [NutritionBasis] is the user-facing source of truth.  Normalized per-100g
/// values are generated solely for compatibility with existing lookup and
/// calculation code.
class CustomFoodService {
  final FoodCacheRepository foods;

  const CustomFoodService(this.foods);

  Future<FoodMacros> remember({
    required String name,
    required NutritionBasis basis,
    double? physicalGrams,
    double? gramsPerPiece,
    FoodProvenance? provenance,
    bool isEstimate = false,
  }) async {
    _validate(
      name: name,
      basis: basis,
      physicalGrams: physicalGrams,
      gramsPerPiece: gramsPerPiece,
    );
    final normalized = customFoodBasisFromNutritionBasis(
      basis: basis,
      physicalGrams: physicalGrams,
    );
    final food = FoodMacros(
      name: name.trim(),
      perHundred: normalized.perHundred,
      source: MacroSource.manual,
      isEstimate: isEstimate || (provenance?.isEstimate ?? false),
      gramsPerPiece: normalized.gramsPerPiece ?? gramsPerPiece,
      basis: normalized.basis,
      provenance: provenance,
      basisPhysicalGrams: physicalGrams,
    );
    await foods.upsertOverride(food);
    return food;
  }

  void _validate({
    required String name,
    required NutritionBasis basis,
    required double? physicalGrams,
    required double? gramsPerPiece,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name');
    }
    if (basis.unit.trim().isEmpty) {
      throw ArgumentError.value(basis.unit, 'unit');
    }
    if (!basis.quantity.isFinite || basis.quantity <= 0) {
      throw ArgumentError.value(basis.quantity, 'basis.quantity');
    }
    if (!_validMacros(basis.macros)) {
      throw ArgumentError.value(basis.macros, 'basis.macros');
    }
    if (physicalGrams != null &&
        (!physicalGrams.isFinite || physicalGrams <= 0)) {
      throw ArgumentError.value(physicalGrams, 'physicalGrams');
    }
    if (gramsPerPiece != null &&
        (!gramsPerPiece.isFinite || gramsPerPiece <= 0)) {
      throw ArgumentError.value(gramsPerPiece, 'gramsPerPiece');
    }
  }

  bool _validMacros(MacroValues macros) =>
      _nonNegativeFinite(macros.kcal) &&
      _nonNegativeFinite(macros.protein) &&
      _nonNegativeFinite(macros.carb) &&
      _nonNegativeFinite(macros.fat) &&
      (macros.fibre == null || _nonNegativeFinite(macros.fibre!));

  bool _nonNegativeFinite(double value) => value.isFinite && value >= 0;
}
