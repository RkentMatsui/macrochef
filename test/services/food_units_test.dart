import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/food_units.dart';

void main() {
  test('maps fixed units and converts compatible quantities', () {
    expect(foodUnitByLabel(' ML ')!.family, FoodUnitFamily.volume);
    expect(
      convertFoodQuantity(1, foodUnitByLabel('cup')!, foodUnitByLabel('ml')!),
      240,
    );
    expect(
      convertFoodQuantity(
        1,
        foodUnitByLabel('slice')!,
        foodUnitByLabel('piece')!,
      ),
      isNull,
    );
  });
  test('rejects invalid quantities and incompatible families', () {
    expect(convertFoodQuantity(0, kFoodUnits.first, kFoodUnits.first), isNull);
    expect(
      convertFoodQuantity(1, foodUnitByLabel('g')!, foodUnitByLabel('ml')!),
      isNull,
    );
  });
}
