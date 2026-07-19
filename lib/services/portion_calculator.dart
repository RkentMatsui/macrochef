import '../models/food_unit_weight.dart';
import '../models/macros.dart';
import 'food_units.dart';
import 'macro_calculator.dart';

enum PortionUnresolvedReason {
  invalidQuantity,
  unsupportedUnit,
  incompatibleUnit,
  missingPhysicalWeight,
}

sealed class PortionCalculation {
  const PortionCalculation();
}

final class ResolvedPortion extends PortionCalculation {
  final double quantity;
  final String unit;
  final MacroValues macros;
  final double? physicalGrams;
  final FoodUnitWeight? acceptedUnitWeight;
  const ResolvedPortion({
    required this.quantity,
    required this.unit,
    required this.macros,
    required this.physicalGrams,
    this.acceptedUnitWeight,
  });
}

final class UnresolvedPortion extends PortionCalculation {
  final PortionUnresolvedReason reason;
  final String? basisUnit;
  const UnresolvedPortion(this.reason, {this.basisUnit});
}

class PortionCalculator {
  const PortionCalculator._();
  static PortionCalculation calculate({
    required FoodMacros food,
    required double quantity,
    required String unit,
    FoodUnitWeight? unitWeight,
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      return const UnresolvedPortion(PortionUnresolvedReason.invalidQuantity);
    }
    final requested = foodUnitByLabel(unit);
    if (requested == null) {
      return const UnresolvedPortion(PortionUnresolvedReason.unsupportedUnit);
    }
    final basis = food.basis;
    final acceptedWeight = unitWeight?.isValid == true ? unitWeight : null;
    if (basis != null) {
      final basisUnit = foodUnitByLabel(basis.unit);
      if (basisUnit == null) {
        if (requested.family == FoodUnitFamily.mass &&
            MacroCalculator.hasUsablePerHundred(food.perHundred)) {
          final grams = quantity * requested.canonicalFactor;
          return _fromPerHundred(
            food: food,
            quantity: quantity,
            unit: requested.label,
            grams: grams,
          );
        }
        if (_matchesRequested(acceptedWeight, requested) &&
            MacroCalculator.hasUsablePerHundred(food.perHundred)) {
          final grams = quantity * acceptedWeight!.gramsPerUnit;
          return _fromPerHundred(
            food: food,
            quantity: quantity,
            unit: requested.label,
            grams: grams,
            acceptedUnitWeight: acceptedWeight,
          );
        }
        return UnresolvedPortion(
          PortionUnresolvedReason.unsupportedUnit,
          basisUnit: basis.unit,
        );
      }
      final converted = convertFoodQuantity(quantity, requested, basisUnit);
      if (converted != null && _positiveFinite(basis.quantity)) {
        final factor = converted / basis.quantity;
        return ResolvedPortion(
          quantity: quantity,
          unit: requested.label,
          macros: basis.macros.scaled(factor),
          physicalGrams: _positiveFinite(food.basisPhysicalGrams)
              ? food.basisPhysicalGrams! * factor
              : null,
        );
      }

      if (requested.family == FoodUnitFamily.mass) {
        final grams = quantity * requested.canonicalFactor;
        if (_positiveFinite(food.basisPhysicalGrams)) {
          return _fromBasisWeight(
            quantity: quantity,
            unit: requested.label,
            grams: grams,
            basis: basis,
            totalBasisGrams: food.basisPhysicalGrams!,
          );
        }
        if (_matchesBasis(acceptedWeight, basisUnit) &&
            _positiveFinite(basis.quantity)) {
          return _fromBasisWeight(
            quantity: quantity,
            unit: requested.label,
            grams: grams,
            basis: basis,
            totalBasisGrams: basis.quantity * acceptedWeight!.gramsPerUnit,
            acceptedUnitWeight: acceptedWeight,
          );
        }
        if (MacroCalculator.hasUsablePerHundred(food.perHundred)) {
          return _fromPerHundred(
            food: food,
            quantity: quantity,
            unit: requested.label,
            grams: grams,
          );
        }
        return UnresolvedPortion(
          PortionUnresolvedReason.missingPhysicalWeight,
          basisUnit: basisUnit.label,
        );
      }

      if (_matchesRequested(acceptedWeight, requested) &&
          MacroCalculator.hasUsablePerHundred(food.perHundred)) {
        final grams = quantity * acceptedWeight!.gramsPerUnit;
        return _fromPerHundred(
          food: food,
          quantity: quantity,
          unit: requested.label,
          grams: grams,
          acceptedUnitWeight: acceptedWeight,
        );
      }
      return UnresolvedPortion(
        PortionUnresolvedReason.incompatibleUnit,
        basisUnit: basisUnit.label,
      );
    }
    if (requested.family == FoodUnitFamily.mass) {
      final grams = quantity * requested.canonicalFactor;
      return _fromPerHundred(
        food: food,
        quantity: quantity,
        unit: requested.label,
        grams: grams,
      );
    }
    if (_matchesRequested(acceptedWeight, requested) &&
        MacroCalculator.hasUsablePerHundred(food.perHundred)) {
      final grams = quantity * acceptedWeight!.gramsPerUnit;
      return _fromPerHundred(
        food: food,
        quantity: quantity,
        unit: requested.label,
        grams: grams,
        acceptedUnitWeight: acceptedWeight,
      );
    }
    if (requested.label == 'piece' &&
        food.gramsPerPiece != null &&
        _positiveFinite(food.gramsPerPiece)) {
      final grams = quantity * food.gramsPerPiece!;
      return _fromPerHundred(
        food: food,
        quantity: quantity,
        unit: requested.label,
        grams: grams,
      );
    }
    return UnresolvedPortion(
      PortionUnresolvedReason.missingPhysicalWeight,
      basisUnit: food.basis?.unit,
    );
  }

  static ResolvedPortion _fromBasisWeight({
    required double quantity,
    required String unit,
    required double grams,
    required NutritionBasis basis,
    required double totalBasisGrams,
    FoodUnitWeight? acceptedUnitWeight,
  }) => ResolvedPortion(
    quantity: quantity,
    unit: unit,
    macros: basis.macros.scaled(grams / totalBasisGrams),
    physicalGrams: grams,
    acceptedUnitWeight: acceptedUnitWeight,
  );

  static ResolvedPortion _fromPerHundred({
    required FoodMacros food,
    required double quantity,
    required String unit,
    required double grams,
    FoodUnitWeight? acceptedUnitWeight,
  }) => ResolvedPortion(
    quantity: quantity,
    unit: unit,
    macros: MacroCalculator.forGrams(food.perHundred, grams),
    physicalGrams: grams,
    acceptedUnitWeight: acceptedUnitWeight,
  );

  static bool _positiveFinite(double? value) =>
      value != null && value.isFinite && value > 0;

  static bool _matchesBasis(FoodUnitWeight? weight, FoodUnit basisUnit) =>
      weight != null && weight.matchesUnit(basisUnit.label);

  static bool _matchesRequested(FoodUnitWeight? weight, FoodUnit requested) =>
      weight != null && weight.matchesUnit(requested.label);
}
