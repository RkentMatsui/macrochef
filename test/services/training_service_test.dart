import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/training_service.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;
  late TrainingService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    svc = TrainingService(repo);
  });
  tearDown(() => db.close());

  test('toKg converts lb and passes kg through', () {
    expect(TrainingService.toKg(100, 'lb'), closeTo(45.359237, 1e-6));
    expect(TrainingService.toKg(80, 'kg'), 80);
  });

  test('logging a 100 lb set stores canonical kg and remembers entered unit',
      () async {
    final exerciseId = await repo.insertExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'strength',
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
      ),
    );
    final sessionId = await svc.startEmptySession('2026-06-17');

    await svc.logSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: 5,
      weightKg: 100,
      enteredUnit: 'lb',
    );

    final sets = await repo.setsForSession(sessionId);
    expect(sets.single.weightKg, closeTo(45.359, 1e-3));
    expect(sets.single.enteredUnit, 'lb');
    expect(sets.single.reps, 5);
  });

  test('logSet can record a pending (incomplete) set', () async {
    final exerciseId = await repo.insertExercise(ExercisesCompanion.insert(
        name: 'Squat',
        category: 'strength',
        tracksWeight: const Value(true),
        tracksReps: const Value(true)));
    final sessionId = await svc.startEmptySession('2026-06-24');
    await svc.logSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: 8,
      weightKg: 60,
      completed: false,
    );
    final sets = await repo.setsForSession(sessionId);
    expect(sets.single.completed, isFalse);
  });

  test('finishSession computes a non-negative duration from startedAt',
      () async {
    final sessionId = await svc.startEmptySession('2026-06-17');
    await svc.finishSession(sessionId, perceivedEffort: 8);
    final session = await repo.sessionById(sessionId);
    expect(session!.completedAt, isNotNull);
    expect(session.perceivedEffort, 8);
    expect(session.durationSec, isNotNull);
    expect(session.durationSec! >= 0, true);
  });

  test('startFromDay pre-fills incomplete sets from the prescription',
      () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'strength',
        slug: const Value('bench-press'),
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
      ),
    );
    final squat = await repo.insertExercise(
      ExercisesCompanion.insert(
        name: 'Back Squat',
        category: 'strength',
        slug: const Value('back-squat'),
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
      ),
    );

    final programId = await repo.createProgram(name: 'PPL');
    final dayId = await repo.createDay(programId: programId, name: 'Push/Legs');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(3),
        targetReps: const Value('5'),
        targetWeightKg: const Value(60),
      ),
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: squat,
        position: 1,
        targetSets: const Value(3),
        targetReps: const Value('5'),
        targetWeightKg: const Value(100),
      ),
    ]);

    final sessionId = await svc.startFromDay(dayId, '2026-06-17');

    final session = await repo.sessionById(sessionId);
    expect(session!.dayId, dayId);
    expect(session.name, 'PPL · Push/Legs');

    final sets = await repo.setsForSession(sessionId);
    expect(sets.length, 6); // 2 exercises × 3 sets each
    expect(sets.every((s) => s.completed == false), true);
    // First exercise's pre-filled load carried from prescription.
    final benchSets = sets.where((s) => s.exerciseId == bench).toList();
    expect(benchSets.length, 3);
    expect(benchSets.first.weightKg, 60);
    final squatSets = sets.where((s) => s.exerciseId == squat).toList();
    expect(squatSets.length, 3);
    expect(squatSets.first.weightKg, 100);
  });

  test('startFromDay pre-fills each set from the last performed session',
      () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'strength',
        slug: const Value('bench-press'),
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
      ),
    );

    // A prior completed session where the lifter actually pressed 72.5kg × 6.
    final prior = await svc.startEmptySession('2026-06-10');
    await svc.logSet(
      sessionId: prior,
      exerciseId: bench,
      position: 0,
      setIndex: 0,
      reps: 6,
      weightKg: 72.5,
      enteredUnit: 'kg',
      completed: true,
    );
    await svc.finishSession(prior);

    // Program day still prescribes the old target of 60kg.
    final programId = await repo.createProgram(name: 'PPL');
    final dayId = await repo.createDay(programId: programId, name: 'Push');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(2),
        targetReps: const Value('5'),
        targetWeightKg: const Value(60),
      ),
    ]);

    final sessionId = await svc.startFromDay(dayId, '2026-06-17');
    final sets = await repo.setsForSession(sessionId);
    expect(sets.length, 2);
    // Both sets pre-filled from last time (72.5 × 6), not the 60kg target.
    expect(sets[0].weightKg, closeTo(72.5, 1e-6));
    expect(sets[0].reps, 6);
    expect(sets[0].completed, isFalse);
    // Only one set performed last time → later sets reuse it.
    expect(sets[1].weightKg, closeTo(72.5, 1e-6));
  });
}
