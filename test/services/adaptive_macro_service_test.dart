import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/data/repositories/weight_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/services/adaptive_macro_service.dart';
import 'package:macrochef/services/weight_service.dart';

void main() {
  late AppDatabase db;
  late AdaptiveMacroService service;
  late TargetRepository targetRepo;
  late WeightRepository weightRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    targetRepo = TargetRepository(db);
    weightRepo = WeightRepository(db);
    service = AdaptiveMacroService(
      logs: LogRepository(db),
      targets: targetRepo,
      settings: SettingsRepository(db),
      weightService: WeightService(
        weights: weightRepo,
        settings: SettingsRepository(db),
      ),
    );
  });

  tearDown(() => db.close());

  test('returns null with fewer than 7 weight entries', () async {
    // Add a target and 6 weight entries (not enough).
    await targetRepo.setDefault(
      const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 67),
    );
    for (var i = 0; i < 6; i++) {
      await weightRepo.upsert(
        '2026-06-${(i + 1).toString().padLeft(2, '0')}',
        80.0,
      );
    }
    final result = await service.recompute();
    expect(result, isNull);
  });

  test('returns null when no baseline target is set', () async {
    // Seed 14 weight entries but no target.
    for (var i = 0; i < 14; i++) {
      await weightRepo.upsert(
        '2026-06-${(i + 1).toString().padLeft(2, '0')}',
        80.0,
      );
    }
    final result = await service.recompute();
    expect(result, isNull);
  });

  test('with 14 days stable 80 kg + 2000 kcal/day + 2000 kcal maintain target,'
      ' result.kcal closeTo 2000 within 150', () async {
    // Set maintain target.
    await targetRepo.setDefault(
      const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 67),
    );

    // Seed 14 days of stable weight entries (no trend delta).
    final today = DateTime.now();
    for (var i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await weightRepo.upsert(dateStr, 80.0);
    }

    // Seed 14 days of log entries at 2000 kcal each day.
    for (var i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await db
          .into(db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              date: dateStr,
              foodName: 'food',
              grams: 500,
              kcal: 2000,
              protein: 150,
              carb: 200,
              fat: 67,
              source: 'manual',
            ),
          );
    }

    final result = await service.recompute();
    expect(result, isNotNull);
    expect(result!.kcal, closeTo(2000, 150));
  });

  test('goal weight round-trips and clears', () async {
    expect(await service.getGoalWeight(), isNull);
    await service.setGoalWeight(75.0);
    expect(await service.getGoalWeight(), 75.0);
    await service.setGoalWeight(null);
    expect(await service.getGoalWeight(), isNull);
  });

  test('goalFromWeights derives direction with a 0.5 kg deadband', () {
    expect(AdaptiveMacroService.goalFromWeights(82.0, 75.0), 'lose');
    expect(AdaptiveMacroService.goalFromWeights(70.0, 78.0), 'gain');
    expect(AdaptiveMacroService.goalFromWeights(80.0, 80.3), 'maintain');
    expect(AdaptiveMacroService.goalFromWeights(80.0, 80.5), 'maintain');
    expect(AdaptiveMacroService.goalFromWeights(80.0, 81.0), 'gain');
  });

  test(
    'persists a qualified calculation effective on the supplied next day',
    () async {
      await targetRepo.setDefault(
        const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 67),
      );
      final cutoff = DateTime(2026, 7, 14);
      for (var i = 0; i < 14; i++) {
        final date = cutoff.subtract(Duration(days: 13 - i));
        final key = _date(date);
        await weightRepo.upsert(key, 80);
        await db
            .into(db.logEntries)
            .insert(
              LogEntriesCompanion.insert(
                date: key,
                foodName: 'complete day',
                grams: 100,
                kcal: 1200,
                protein: 75,
                carb: 100,
                fat: 30,
                source: 'manual',
              ),
            );
      }

      final result = await service.calculate(
        calculatedThrough: cutoff,
        effectiveFrom: DateTime(2026, 7, 15),
      );

      expect(result, isA<AdaptiveApplied>());
      final applied = result as AdaptiveApplied;
      expect(applied.record.effectiveFrom, '2026-07-15');
      expect(applied.target.protein, 150);
      final carbDeltaCalories = (applied.target.carb - 200) * 4;
      final fatDeltaCalories = (applied.target.fat - 67) * 9;
      expect(
        carbDeltaCalories / fatDeltaCalories,
        closeTo((200 * 4) / (67 * 9), 0.001),
      );
      expect(await targetRepo.get('2026-07-14'), isNotNull);
      expect((await targetRepo.get('2026-07-15'))!.kcal, applied.target.kcal);
    },
  );

  test('excludes one-entry partial days and future observations', () async {
    await targetRepo.setDefault(
      const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 67),
    );
    final cutoff = DateTime(2026, 7, 14);
    for (var i = 0; i < 7; i++) {
      final key = _date(cutoff.subtract(Duration(days: i)));
      await weightRepo.upsert(key, 80);
      await db
          .into(db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              date: key,
              foodName: 'partial',
              grams: 10,
              kcal: 100,
              protein: 1,
              carb: 1,
              fat: 1,
              source: 'manual',
            ),
          );
    }
    await weightRepo.upsert('2026-08-01', 90);
    await db
        .into(db.logEntries)
        .insert(
          LogEntriesCompanion.insert(
            date: '2026-08-01',
            foodName: 'future',
            grams: 1,
            kcal: 9999,
            protein: 1,
            carb: 1,
            fat: 1,
            source: 'manual',
          ),
        );

    final result = await service.calculate(
      calculatedThrough: cutoff,
      effectiveFrom: cutoff.add(const Duration(days: 1)),
    );
    expect(result, isA<AdaptiveInsufficientData>());
    final insufficient = result as AdaptiveInsufficientData;
    expect(insufficient.qualifiedIntakeDays, 0);
    expect(insufficient.weightObservationCount, 7);
    expect(await targetRepo.latestAdaptive(), isNull);
  });

  test('requires at least 14 calendar days even with seven entries', () async {
    await targetRepo.setDefault(
      const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 67),
    );
    final cutoff = DateTime(2026, 7, 14);
    for (var i = 0; i < 7; i++) {
      final key = _date(cutoff.subtract(Duration(days: 6 - i)));
      await weightRepo.upsert(key, 80);
      await db
          .into(db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              date: key,
              foodName: 'complete day',
              grams: 100,
              kcal: 1200,
              protein: 75,
              carb: 100,
              fat: 30,
              source: 'manual',
            ),
          );
    }

    final result = await service.calculate(
      calculatedThrough: cutoff,
      effectiveFrom: cutoff.add(const Duration(days: 1)),
    );

    expect(result, isA<AdaptiveInsufficientData>());
    expect(
      (result as AdaptiveInsufficientData).reason,
      contains('14 calendar days'),
    );
  });
}

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
