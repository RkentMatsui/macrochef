import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/plate_calculator.dart';

void main() {
  group('PlateCalculator.solve', () {
    test('exact load: 100kg on a 20kg bar = 25+15 per side', () {
      final l = PlateCalculator.solve(target: 100, bar: 20, unit: 'kg');
      expect(l.exact, true);
      expect(l.total, 100);
      expect(l.perSideWeight, 40);
      expect(l.perSide.map((p) => p.weight).toList(), [25, 15]);
      expect(l.perSide.every((p) => p.count == 1), true);
    });

    test('uses fractional plates: 102.5kg = 25+15+1.25 per side', () {
      final l = PlateCalculator.solve(target: 102.5, bar: 20, unit: 'kg');
      expect(l.exact, true);
      expect(l.perSide.map((p) => p.weight).toList(), [25, 15, 1.25]);
    });

    test('repeats a denomination: 120kg = two 25s + ... per side', () {
      final l = PlateCalculator.solve(target: 120, bar: 20, unit: 'kg');
      // perSide 50 → 25×2.
      expect(l.exact, true);
      expect(l.perSide.first.weight, 25);
      expect(l.perSide.first.count, 2);
      expect(l.total, 120);
    });

    test('lb: 135lb on a 45lb bar = one 45 per side', () {
      final l = PlateCalculator.solve(target: 135, bar: 45, unit: 'lb');
      expect(l.exact, true);
      expect(l.perSide, hasLength(1));
      expect(l.perSide.first.weight, 45);
      expect(l.perSide.first.count, 1);
    });

    test('target below bar yields just the bar (no plates)', () {
      final l = PlateCalculator.solve(target: 15, bar: 20, unit: 'kg');
      expect(l.perSide, isEmpty);
      expect(l.total, 20);
      expect(l.exact, false);
    });

    test('inexact target loads closest below and flags not-exact', () {
      // perSide would be 0.5 — smaller than the smallest (1.25) plate.
      final l = PlateCalculator.solve(target: 21, bar: 20, unit: 'kg');
      expect(l.perSide, isEmpty);
      expect(l.total, 20);
      expect(l.exact, false);
    });

    test('bar-only target is exact', () {
      final l = PlateCalculator.solve(target: 20, bar: 20, unit: 'kg');
      expect(l.total, 20);
      expect(l.exact, true);
    });
  });

  group('totals', () {
    test('totalForCounts mirrors solve', () {
      final l = PlateCalculator.solve(target: 100, bar: 20, unit: 'kg');
      final counts = {for (final p in l.perSide) p.weight: p.count};
      expect(
          PlateCalculator.totalForCounts(bar: 20, counts: counts), l.total);
    });
  });
}
