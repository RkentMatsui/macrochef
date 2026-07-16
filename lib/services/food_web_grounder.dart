import '../models/macros.dart';

/// Provider-independent capability for grounding an otherwise unresolved food
/// with cited public web information. A null result means no usable evidence
/// was found; callers must continue to their ordinary estimate fallback.
abstract class FoodWebGrounder {
  Future<GroundedFoodResult?> ground(String foodName);

  /// Searches specifically for a nutrition basis compatible with [requestedUnit].
  /// Implementations that cannot refine their query retain the normal grounding
  /// behavior; the caller still validates that the returned basis is usable.
  Future<GroundedFoodResult?> groundForPortion(
    String foodName, {
    required String requestedUnit,
  }) => ground(foodName);
}

/// Nutrition returned by a web-grounding provider, expressed in the source's
/// original serving/portion basis. This basis is authoritative and is never
/// replaced by [derivedPerHundred].
class GroundedFoodResult {
  final String name;
  final NutritionBasis basis;
  final double? physicalGrams;
  final double? fibre;
  final double? sodium;
  final FoodProvenance provenance;

  const GroundedFoodResult({
    required this.name,
    required this.basis,
    required this.physicalGrams,
    required this.fibre,
    required this.sodium,
    required this.provenance,
  });

  /// True when any nutrition field was inferred rather than directly cited.
  bool get isEstimate => provenance.isEstimate;

  /// Returns null when this is safe to accept as web-grounded food data.
  ///
  /// Validation is deliberately non-throwing so a malformed provider response
  /// can fail soft to the normal AI estimate path.
  String? validate() {
    if (name.trim().isEmpty) return 'Food name is required.';
    if (!provenance.isValid) return 'A valid cited source is required.';
    if (!_positiveFinite(basis.quantity)) {
      return 'Basis quantity must be positive.';
    }
    if (basis.unit.trim().isEmpty) return 'Basis unit is required.';
    if (!_nonNegativeFinite(basis.macros.kcal) ||
        !_nonNegativeFinite(basis.macros.protein) ||
        !_nonNegativeFinite(basis.macros.carb) ||
        !_nonNegativeFinite(basis.macros.fat) ||
        !_optionalNonNegativeFinite(basis.macros.fibre) ||
        !_optionalNonNegativeFinite(physicalGrams) ||
        !_optionalNonNegativeFinite(fibre) ||
        !_optionalNonNegativeFinite(sodium)) {
      return 'Nutrition values must be finite and non-negative.';
    }
    return null;
  }

  bool get isValid => validate() == null;

  /// Derived compatibility values only. For a serving/count/volume basis with
  /// no explicit source weight, per-100-g scaling would be fabricated, so zero
  /// is returned and callers must scale from [basis] instead.
  PerHundred get derivedPerHundred {
    final grams = physicalGrams ?? _massBasisGrams(basis.quantity, basis.unit);
    if (grams == null || !_positiveFinite(grams)) return PerHundred.zero;
    final factor = 100 / grams;
    return PerHundred(
      kcal: basis.macros.kcal * factor,
      protein: basis.macros.protein * factor,
      carb: basis.macros.carb * factor,
      fat: basis.macros.fat * factor,
      fibre: (fibre ?? basis.macros.fibre) == null
          ? null
          : (fibre ?? basis.macros.fibre)! * factor,
      sodium: sodium == null ? null : sodium! * factor,
    );
  }
}

bool _positiveFinite(double value) => value.isFinite && value > 0;
bool _nonNegativeFinite(double value) => value.isFinite && value >= 0;
bool _optionalNonNegativeFinite(double? value) =>
    value == null || _nonNegativeFinite(value);

double? _massBasisGrams(double quantity, String unit) {
  switch (unit.trim().toLowerCase()) {
    case 'g':
      return quantity;
    case 'kg':
      return quantity * 1000;
    case 'oz':
      return quantity * 28.3495;
    default:
      return null;
  }
}
