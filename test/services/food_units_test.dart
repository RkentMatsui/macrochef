import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/food_units.dart';

void main() {
  test('grams is the default unit and converts 1:1', () {
    expect(kFoodUnits.first.label, 'g');
    expect(kFoodUnits.first.needsEstimate, isFalse);
    expect(kFoodUnits.first.gramsPerUnit, 1);
  });

  test('fixed-factor units convert arithmetically', () {
    final byLabel = {for (final u in kFoodUnits) u.label: u};
    expect(byLabel['kg']!.gramsPerUnit, 1000);
    expect(byLabel['oz']!.gramsPerUnit, closeTo(28.3495, 0.0001));
    expect(byLabel['kg']!.needsEstimate, isFalse);
    expect(byLabel['oz']!.needsEstimate, isFalse);
  });

  test('household measures require a per-food estimate', () {
    final byLabel = {for (final u in kFoodUnits) u.label: u};
    for (final label in ['cup', 'tbsp', 'tsp', 'ml', 'piece', 'slice', 'serving']) {
      expect(byLabel[label], isNotNull, reason: '$label should be offered');
      expect(byLabel[label]!.needsEstimate, isTrue,
          reason: '$label weight varies by food');
      expect(byLabel[label]!.gramsPerUnit, isNull);
    }
  });
}
