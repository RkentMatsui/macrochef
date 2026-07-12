import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/daily_log_service.dart';

void main() {
  late AppDatabase db;
  late DailyLogService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = DailyLogService(
      logs: LogRepository(db),
      targets: TargetRepository(db),
    );
  });

  tearDown(() => db.close());

  test('log two foods and totals sums kcal correctly', () async {
    const date = '2026-06-14';

    // chicken: 200g, 330 kcal, 62g protein, 0 carb, 7.2g fat
    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    // rice: 150g, 195 kcal, 4.05g protein, 43.35 carb, 0.45g fat
    await service.log(
      date,
      name: 'white rice',
      grams: 150,
      macros: const MacroValues(kcal: 195, protein: 4.05, carb: 43.35, fat: 0.45),
      source: MacroSource.usda,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.kcal, closeTo(525, 0.01));
    expect(totals.consumed.protein, closeTo(66.05, 0.01));
    expect(totals.target, isNull); // no target set
  });

  test('copyDay re-logs every entry from one day to another', () async {
    await service.log('2026-06-13',
        name: 'oats',
        grams: 80,
        macros: const MacroValues(kcal: 300, protein: 10, carb: 50, fat: 6),
        source: MacroSource.usda);
    await service.log('2026-06-13',
        name: 'eggs',
        grams: 100,
        macros: const MacroValues(kcal: 155, protein: 13, carb: 1, fat: 11),
        source: MacroSource.manual);

    final n = await service.copyDay('2026-06-13', '2026-06-14');
    expect(n, 2);

    final src = await service.totals('2026-06-13');
    final dst = await service.totals('2026-06-14');
    expect(dst.consumed.kcal, closeTo(src.consumed.kcal, 0.01));
    expect(dst.consumed.protein, closeTo(src.consumed.protein, 0.01));
  });

  test('copyDay returns 0 when the source day is empty', () async {
    expect(await service.copyDay('2026-01-01', '2026-06-14'), 0);
  });

  test('setTarget persists and is returned in totals', () async {
    const date = '2026-06-14';

    await service.setTarget(
      const DailyTarget(kcal: 2000, protein: 180, carb: 200, fat: 60),
    );

    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    final totals = await service.totals(date);
    expect(totals.target, isNotNull);
    expect(totals.target!.protein, closeTo(180, 0.01));
    expect(totals.consumed.kcal, closeTo(330, 0.01));
  });

  test('totals for different date returns only that day entries', () async {
    await service.log(
      '2026-06-14',
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    await service.log(
      '2026-06-13',
      name: 'oats',
      grams: 100,
      macros: const MacroValues(kcal: 370, protein: 13, carb: 66, fat: 7),
      source: MacroSource.manual,
    );

    final totals = await service.totals('2026-06-14');
    expect(totals.consumed.kcal, closeTo(330, 0.01));
  });

  test('fibre sums across two entries with fibre', () async {
    const date = '2026-06-15';

    await service.log(
      date,
      name: 'oats',
      grams: 100,
      macros: const MacroValues(
          kcal: 370, protein: 13, carb: 66, fat: 7, fibre: 10.6),
      source: MacroSource.usda,
    );

    await service.log(
      date,
      name: 'broccoli',
      grams: 100,
      macros: const MacroValues(
          kcal: 34, protein: 2.8, carb: 6.6, fat: 0.4, fibre: 2.4),
      source: MacroSource.usda,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.fibre, isNotNull);
    expect(totals.consumed.fibre!, closeTo(13.0, 0.01));
  });

  test('fibre is null in totals when no entry carries fibre', () async {
    const date = '2026-06-16';

    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.fibre, isNull);
  });

  group('frequentFoods / relog', () {
    test('ranks by occurrence count, carries last-logged portion', () async {
      // chicken logged 3×, rice 1× — across several days within the window.
      await service.log('2026-06-10',
          name: 'chicken breast',
          grams: 200,
          macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
          source: MacroSource.off);
      await service.log('2026-06-11',
          name: 'white rice',
          grams: 150,
          macros: const MacroValues(kcal: 195, protein: 4, carb: 43, fat: 0.5),
          source: MacroSource.usda);
      await service.log('2026-06-12',
          name: 'chicken breast',
          grams: 220,
          macros: const MacroValues(kcal: 363, protein: 68, carb: 0, fat: 7.9),
          source: MacroSource.off);
      // Most-recent chicken portion = 180g — this is the one re-log should use.
      await service.log('2026-06-14',
          name: 'chicken breast',
          grams: 180,
          macros: const MacroValues(kcal: 297, protein: 56, carb: 0, fat: 6.5),
          source: MacroSource.off);

      final freq = await service.frequentFoods('2026-06-15');
      expect(freq.first.name, 'chicken breast');
      expect(freq.first.count, 3);
      // Carries the LAST-logged portion, not the first.
      expect(freq.first.grams, closeTo(180, 0.01));
      expect(freq.first.macros.kcal, closeTo(297, 0.01));
      expect(freq.first.source, MacroSource.off);
      expect(freq[1].name, 'white rice');
      expect(freq[1].count, 1);
    });

    test('excludes foods outside the lookback window', () async {
      await service.log('2026-01-01',
          name: 'old food',
          grams: 100,
          macros: const MacroValues(kcal: 100, protein: 1, carb: 1, fat: 1),
          source: MacroSource.manual);

      final freq = await service.frequentFoods('2026-06-15', windowDays: 60);
      expect(freq.where((f) => f.name == 'old food'), isEmpty);
    });

    test('relog re-inserts the same portion to a new date', () async {
      await service.log('2026-06-10',
          name: 'chicken breast',
          grams: 200,
          macros: const MacroValues(
              kcal: 330, protein: 62, carb: 0, fat: 7.2, fibre: 0),
          source: MacroSource.off);

      final freq = await service.frequentFoods('2026-06-15');
      await service.relog('2026-06-15', freq.first);

      final totals = await service.totals('2026-06-15');
      expect(totals.consumed.kcal, closeTo(330, 0.01));
      expect(totals.consumed.protein, closeTo(62, 0.01));
    });

    test('limit caps the number of foods returned', () async {
      for (var i = 0; i < 20; i++) {
        await service.log('2026-06-10',
            name: 'food $i',
            grams: 100,
            macros: const MacroValues(kcal: 100, protein: 1, carb: 1, fat: 1),
            source: MacroSource.manual);
      }
      final freq = await service.frequentFoods('2026-06-15', limit: 5);
      expect(freq.length, 5);
    });
  });
}
