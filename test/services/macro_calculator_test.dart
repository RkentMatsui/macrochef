import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/macro_calculator.dart';

void main() {
  test('200g of chicken breast calculates correct macros', () {
    const perHundred = PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);
    final result = MacroCalculator.forGrams(perHundred, 200);

    expect(result.kcal, closeTo(330, 0.01));
    expect(result.protein, closeTo(62, 0.01));
    expect(result.carb, closeTo(0, 0.01));
    expect(result.fat, closeTo(7.2, 0.01));
  });

  test('100g returns same as perHundred values', () {
    const perHundred = PerHundred(kcal: 100, protein: 20, carb: 5, fat: 2);
    final result = MacroCalculator.forGrams(perHundred, 100);

    expect(result.kcal, closeTo(100, 0.01));
    expect(result.protein, closeTo(20, 0.01));
    expect(result.carb, closeTo(5, 0.01));
    expect(result.fat, closeTo(2, 0.01));
  });
}
