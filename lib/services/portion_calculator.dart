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
  const ResolvedPortion({
    required this.quantity,
    required this.unit,
    required this.macros,
    required this.physicalGrams,
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
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      return const UnresolvedPortion(PortionUnresolvedReason.invalidQuantity);
    }
    final requested = foodUnitByLabel(unit);
    if (requested == null) {
      return const UnresolvedPortion(PortionUnresolvedReason.unsupportedUnit);
    }
    if (food.basis != null) {
      final basisUnit = foodUnitByLabel(food.basis!.unit);
      if (basisUnit == null) {
        return UnresolvedPortion(
          PortionUnresolvedReason.unsupportedUnit,
          basisUnit: food.basis!.unit,
        );
      }
      final converted = convertFoodQuantity(quantity, requested, basisUnit);
      if (converted == null) {
        return UnresolvedPortion(
          PortionUnresolvedReason.incompatibleUnit,
          basisUnit: basisUnit.label,
        );
      }
      final factor = converted / food.basis!.quantity;
      return ResolvedPortion(
        quantity: quantity,
        unit: requested.label,
        macros: food.basis!.macros.scaled(factor),
        physicalGrams: food.basisPhysicalGrams == null
            ? null
            : food.basisPhysicalGrams! * factor,
      );
    }
    if (requested.family == FoodUnitFamily.mass) {
      final grams = quantity * requested.canonicalFactor;
      return ResolvedPortion(
        quantity: quantity,
        unit: requested.label,
        macros: MacroCalculator.forGrams(food.perHundred, grams),
        physicalGrams: grams,
      );
    }
    if (requested.family == FoodUnitFamily.count &&
        food.gramsPerPiece != null &&
        food.gramsPerPiece!.isFinite &&
        food.gramsPerPiece! > 0) {
      final grams = quantity * food.gramsPerPiece!;
      return ResolvedPortion(
        quantity: quantity,
        unit: requested.label,
        macros: MacroCalculator.forGrams(food.perHundred, grams),
        physicalGrams: grams,
      );
    }
    return UnresolvedPortion(
      PortionUnresolvedReason.missingPhysicalWeight,
      basisUnit: food.basis?.unit,
    );
  }
}
