import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';

void main() {
  test('MacroValues addition sums each field', () {
    const a = MacroValues(kcal: 100, protein: 10, carb: 5, fat: 2);
    const b = MacroValues(kcal: 50, protein: 4, carb: 3, fat: 1);
    final sum = a + b;
    expect(sum.kcal, 150);
    expect(sum.protein, 14);
    expect(sum.carb, 8);
    expect(sum.fat, 3);
  });

  test('MacroValues.zero is all zeros', () {
    expect(MacroValues.zero.kcal, 0);
    expect(MacroValues.zero.protein, 0);
  });
}
