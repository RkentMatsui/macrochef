import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/exercise_library.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
  });
  tearDown(() => db.close());

  test('catalog covers all four categories with valid flags', () {
    final categories = kBuiltInExercises.map((e) => e.category).toSet();
    expect(categories, containsAll(['strength', 'cardio', 'class', 'mobility']));
    expect(kBuiltInExercises.length, greaterThanOrEqualTo(40));

    // Slugs are unique.
    final slugs = kBuiltInExercises.map((e) => e.slug).toList();
    expect(slugs.toSet().length, slugs.length);

    // Each exercise tracks at least one metric.
    for (final e in kBuiltInExercises) {
      expect(
        e.tracksWeight || e.tracksReps || e.tracksDuration || e.tracksDistance,
        true,
        reason: '${e.slug} must track at least one metric',
      );
    }
  });

  test('secondary-muscle data is valid: known keys, never repeats primary', () {
    const validKeys = {
      'chest', 'back', 'shoulders', 'rear-delts', 'biceps', 'triceps', 'core',
      'quads', 'hamstrings', 'glutes', 'calves', 'forearms',
    };
    final bySlug = {for (final e in kBuiltInExercises) e.slug: e};
    for (final entry in kSecondaryMuscles.entries) {
      // Every keyed slug is a real built-in exercise.
      expect(bySlug.containsKey(entry.key), true,
          reason: '${entry.key} is not a built-in slug');
      final primary = bySlug[entry.key]?.primaryMuscle;
      for (final m in entry.value) {
        expect(validKeys.contains(m), true,
            reason: '${entry.key}: "$m" is not a valid muscle key');
        expect(m == primary, false,
            reason: '${entry.key}: secondary "$m" repeats the primary');
      }
    }
  });

  test('seeding is idempotent', () async {
    await seedExercises(repo);
    final afterFirst = (await repo.allExercises()).length;
    expect(afterFirst, kBuiltInExercises.length);

    await seedExercises(repo);
    final afterSecond = (await repo.allExercises()).length;
    expect(afterSecond, afterFirst);
  });

  test('every built-in exercise has a how-to description', () {
    for (final e in kBuiltInExercises) {
      expect(e.description, isNotNull,
          reason: '${e.slug} is missing a description');
      expect(e.description!.trim(), isNotEmpty);
    }
  });

  test('forearm exercises are tracked under "forearms"', () {
    final forearms =
        kBuiltInExercises.where((e) => e.primaryMuscle == 'forearms').toList();
    expect(forearms, isNotEmpty);
    expect(forearms.map((e) => e.slug), contains('wrist-curl'));
  });

  test('seedExercises backfills a missing description onto an existing built-in',
      () async {
    // Simulate a built-in seeded before descriptions existed (description null).
    final seed = kBuiltInExercises.firstWhere((e) => e.slug == 'bench-press');
    final id = await repo.insertExercise(
      ExercisesCompanion.insert(
        slug: Value(seed.slug),
        name: seed.name,
        category: seed.category,
        primaryMuscle: Value(seed.primaryMuscle),
      ),
    );
    expect((await repo.exerciseById(id))!.description, isNull);

    await seedExercises(repo);

    expect((await repo.exerciseById(id))!.description, seed.description);
    // No duplicate row for the backfilled slug.
    final benches =
        (await repo.allExercises()).where((e) => e.slug == 'bench-press');
    expect(benches.length, 1);
  });
}
