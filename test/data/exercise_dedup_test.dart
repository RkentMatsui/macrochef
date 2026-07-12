import 'package:drift/drift.dart';
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

  test('dedupeExercisesByName keeps one row per normalized name', () async {
    // Two "Bench Press" rows: a built-in (slug) and a custom duplicate.
    await repo.insertExercise(ExercisesCompanion.insert(
        slug: const Value('bench-press'),
        name: 'Bench Press',
        category: 'strength',
        primaryMuscle: const Value('chest')));
    await repo.insertExercise(ExercisesCompanion.insert(
        name: 'bench press', // different case, no slug
        category: 'strength',
        isCustom: const Value(true)));

    final removed = await repo.dedupeExercisesByName();
    expect(removed, 1);

    final all = await repo.allExercises();
    final benches =
        all.where((e) => e.name.toLowerCase() == 'bench press').toList();
    expect(benches.length, 1);
    // The surviving row is the built-in (slug preferred).
    expect(benches.first.slug, 'bench-press');
  });

  test('re-points logged sets from the removed duplicate to the survivor',
      () async {
    final keepId = await repo.insertExercise(ExercisesCompanion.insert(
        slug: const Value('squat'), name: 'Squat', category: 'strength'));
    final dupId = await repo.insertExercise(ExercisesCompanion.insert(
        name: 'squat', category: 'strength', isCustom: const Value(true)));

    final sessionId = await repo.startSession(date: '2026-06-24');
    await repo.addSet(SetEntriesCompanion.insert(
        sessionId: sessionId,
        exerciseId: dupId,
        position: 0,
        setIndex: 0));

    await repo.dedupeExercisesByName();

    final sets = await repo.setsForSession(sessionId);
    expect(sets.single.exerciseId, keepId);
  });

  test('returns 0 when there are no duplicates (idempotent)', () async {
    await repo.insertExercise(ExercisesCompanion.insert(
        slug: const Value('deadlift'),
        name: 'Deadlift',
        category: 'strength'));
    expect(await repo.dedupeExercisesByName(), 0);
  });

  test('re-seeding backfills a re-pointed primaryMuscle onto a built-in',
      () async {
    // Simulate a built-in seeded before the catalog re-pointed its muscle.
    final id = await repo.insertExercise(ExercisesCompanion.insert(
        slug: const Value('hip-adduction'),
        name: 'Hip Adduction',
        category: 'strength',
        primaryMuscle: const Value('quads')));

    await seedExercises(repo); // current catalog says 'adductors'

    final ex = await repo.exerciseById(id);
    expect(ex!.primaryMuscle, 'adductors');
  });
}
