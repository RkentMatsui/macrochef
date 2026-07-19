import '../models/food_unit_weight.dart';
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

  /// Searches for cited grams for exactly one [requestedUnit].
  ///
  /// Grounders which do not support unit-weight recovery return null; callers
  /// can represent that outcome without treating it as an exception.
  Future<GroundedUnitWeightResult?> groundUnitWeight(
    String foodName, {
    required String requestedUnit,
  }) async => null;
}

/// Provider-independent cited unit-weight evidence returned by a web grounder.
class GroundedUnitWeightResult {
  final FoodUnitWeight weight;

  const GroundedUnitWeightResult._(this.weight);

  /// Rejects malformed provider evidence before it can enter a success path.
  static GroundedUnitWeightResult? tryCreate(FoodUnitWeight weight) =>
      weight.isValid ? GroundedUnitWeightResult._(weight) : null;

  bool get isEstimate => weight.isEstimate;
  String? validate() => weight.validate();
  bool get isValid => validate() == null;
}

/// A non-throwing, exhaustive result for recovering a requested unit weight.
sealed class UnitWeightRecoveryResult {
  const UnitWeightRecoveryResult();

  FoodUnitWeight? get weight;

  /// Cache evidence is accepted only when it remains valid.
  factory UnitWeightRecoveryResult.cache(FoodUnitWeight weight) =>
      weight.isValid
      ? UnitWeightCacheHit._(weight)
      : const UnitWeightUnavailable();

  /// Web evidence selects its typed estimate state from its validated kind.
  factory UnitWeightRecoveryResult.web(FoodUnitWeight weight) {
    if (!weight.isValid) return const UnitWeightUnavailable();
    return switch (weight.kind) {
      FoodUnitWeightKind.published => UnitWeightWebPublished._(weight),
      FoodUnitWeightKind.average => UnitWeightWebAverage._(weight),
    };
  }
}

final class UnitWeightCacheHit extends UnitWeightRecoveryResult {
  @override
  final FoodUnitWeight weight;

  const UnitWeightCacheHit._(this.weight);
}

final class UnitWeightWebPublished extends UnitWeightRecoveryResult {
  @override
  final FoodUnitWeight weight;

  const UnitWeightWebPublished._(this.weight);
}

final class UnitWeightWebAverage extends UnitWeightRecoveryResult {
  @override
  final FoodUnitWeight weight;

  const UnitWeightWebAverage._(this.weight);
}

final class UnitWeightUnavailable extends UnitWeightRecoveryResult {
  const UnitWeightUnavailable();

  @override
  FoodUnitWeight? get weight => null;
}

final class UnitWeightFailed extends UnitWeightRecoveryResult {
  /// A user-safe diagnostic; no exception is needed for normal UI flow.
  final String? message;

  const UnitWeightFailed([this.message]);

  @override
  FoodUnitWeight? get weight => null;
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
