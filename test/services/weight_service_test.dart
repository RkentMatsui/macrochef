import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/weight_repository.dart';
import 'package:macrochef/services/weight_service.dart';

void main() {
  late AppDatabase db;
  late WeightService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = WeightService(
      weights: WeightRepository(db),
      settings: SettingsRepository(db),
    );
  });

  tearDown(() => db.close());

  test('trendSeries returns empty list when no entries exist', () async {
    final series = await service.trendSeries();
    expect(series, isEmpty);
  });

  test('trendSeries seeds trend with the first entry value', () async {
    await service.logWeight('2026-06-01', 80.0);
    final series = await service.trendSeries();
    expect(series.length, 1);
    expect(series.first.trend, closeTo(80.0, 0.001));
    expect(series.first.raw, closeTo(80.0, 0.001));
  });

  test('trendSeries applies EWMA alpha=0.1 (80 then 82 -> trend[1] ≈ 80.2)',
      () async {
    await service.logWeight('2026-06-01', 80.0);
    await service.logWeight('2026-06-02', 82.0);
    final series = await service.trendSeries();
    expect(series.length, 2);
    // trend[0] = 80.0 (seed)
    // trend[1] = 0.1 * 82 + 0.9 * 80 = 8.2 + 72 = 80.2
    expect(series[1].trend, closeTo(80.2, 0.001));
    expect(series[1].raw, closeTo(82.0, 0.001));
  });

  test('logWeight deduplicates same day', () async {
    await service.logWeight('2026-06-01', 80.0);
    await service.logWeight('2026-06-01', 81.5);
    final history = await service.history();
    expect(history.length, 1);
    expect(history.first.kg, 81.5);
  });

  test('forDate returns null when date not logged', () async {
    final entry = await service.forDate('2099-01-01');
    expect(entry, isNull);
  });

  test('forDate returns entry when logged', () async {
    await service.logWeight('2026-06-01', 75.0);
    final entry = await service.forDate('2026-06-01');
    expect(entry, isNotNull);
    expect(entry!.kg, 75.0);
  });

  test('kg<->lb conversion matches the standard factor and round-trips', () {
    // 100 kg ≈ 220.462 lb (1 lb = 0.45359237 kg).
    expect(WeightService.kgToLb(100), closeTo(220.462, 0.01));
    expect(WeightService.lbToKg(220.462), closeTo(100, 0.001));
    // Round-trip is lossless within float tolerance.
    expect(WeightService.lbToKg(WeightService.kgToLb(73.4)),
        closeTo(73.4, 0.0001));
  });

  test('isLbs / unitLabel reflect the stored weight_unit setting', () async {
    expect(await service.isLbs, isFalse); // default kg
    expect(await service.unitLabel, 'kg');
    await service.setUnit('lb');
    expect(await service.isLbs, isTrue);
    expect(await service.unitLabel, 'lb');
  });
}
