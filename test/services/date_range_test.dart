import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/date_range.dart';

void main() {
  test('lastNDays returns n ascending date strings ending on today', () {
    final days = lastNDays('2026-06-15', 7);
    expect(days.length, 7);
    expect(days.first, '2026-06-09');
    expect(days.last, '2026-06-15');
  });

  test('lastNDays crosses month boundary correctly', () {
    final days = lastNDays('2026-03-02', 4);
    expect(days, ['2026-02-27', '2026-02-28', '2026-03-01', '2026-03-02']);
  });

  test('lastNDays n=1 is just today', () {
    expect(lastNDays('2026-06-15', 1), ['2026-06-15']);
  });

  group('nDaysAgo', () {
    test('n=0 returns today', () {
      expect(nDaysAgo('2026-06-15', 0), '2026-06-15');
    });
    test('n=1 returns yesterday', () {
      expect(nDaysAgo('2026-06-15', 1), '2026-06-14');
    });
    test('n=7 returns one week ago', () {
      expect(nDaysAgo('2026-06-15', 7), '2026-06-08');
    });
    test('crosses month boundary', () {
      expect(nDaysAgo('2026-03-02', 3), '2026-02-27');
    });
    test('crosses year boundary', () {
      expect(nDaysAgo('2026-01-02', 3), '2025-12-30');
    });
    test('output is zero-padded', () {
      expect(nDaysAgo('2026-01-10', 5), '2026-01-05');
    });
  });
}
