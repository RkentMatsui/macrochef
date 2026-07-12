import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
  });
  tearDown(() => db.close());

  test('insert exercise, start session, add two sets, read back', () async {
    final exerciseId = await repo.insertExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'strength',
        slug: const Value('bench-press'),
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
      ),
    );

    final exercises = await repo.allExercises();
    expect(exercises.length, 1);
    expect(exercises.first.name, 'Bench Press');

    final sessionId = await repo.startSession(date: '2026-06-17', name: 'Push');
    final session = await repo.sessionById(sessionId);
    expect(session, isNotNull);
    expect(session!.name, 'Push');
    expect(session.startedAt, isNotNull);
    expect(session.completedAt, null);

    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: const Value(8),
      weightKg: const Value(60.0),
    ));
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 1,
      reps: const Value(8),
      weightKg: const Value(62.5),
    ));

    final sets = await repo.setsForSession(sessionId);
    expect(sets.length, 2);
    expect(sets[0].setIndex, 0);
    expect(sets[0].weightKg, 60.0);
    expect(sets[1].setIndex, 1);
    expect(sets[1].weightKg, 62.5);
  });

  test('finishSession stamps completedAt and duration', () async {
    final id = await repo.startSession(date: '2026-06-17');
    await repo.finishSession(id, durationSec: 1800, perceivedEffort: 7);
    final session = await repo.sessionById(id);
    expect(session!.completedAt, isNotNull);
    expect(session.durationSec, 1800);
    expect(session.perceivedEffort, 7);
  });

  test('deleteSession removes the session and its sets', () async {
    final exerciseId = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Squat', category: 'strength'),
    );
    final sessionId = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: const Value(5),
    ));
    // A second untouched session must survive the delete.
    final otherId = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: otherId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: const Value(5),
    ));

    await repo.deleteSession(sessionId);

    expect(await repo.sessionById(sessionId), isNull);
    expect((await repo.setsForSession(sessionId)).isEmpty, isTrue);
    expect(await repo.sessionById(otherId), isNotNull);
    expect((await repo.setsForSession(otherId)).length, 1);
  });

  test('updateSet and deleteSet work', () async {
    final exerciseId = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Row', category: 'strength'),
    );
    final sessionId = await repo.startSession(date: '2026-06-17');
    final setId = await repo.addSet(SetEntriesCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: 0,
      setIndex: 0,
      reps: const Value(10),
    ));

    await repo.updateSet(setId, const SetEntriesCompanion(reps: Value(12)));
    var sets = await repo.setsForSession(sessionId);
    expect(sets.single.reps, 12);

    await repo.deleteSet(setId);
    sets = await repo.setsForSession(sessionId);
    expect(sets, isEmpty);
  });

  test('recentSessions returns newest first within limit', () async {
    await repo.startSession(date: '2026-06-15');
    await repo.startSession(date: '2026-06-16');
    final newest = await repo.startSession(date: '2026-06-17');

    final recent = await repo.recentSessions(limit: 2);
    expect(recent.length, 2);
    expect(recent.first.id, newest);
  });

  test('lastSetFor returns the most recent completed working set', () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench Press', category: 'strength'),
    );

    // Never performed → null.
    expect(await repo.lastSetFor(bench), isNull);

    // Older session.
    final older = await repo.startSession(date: '2026-06-15');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: older,
      exerciseId: bench,
      position: 0,
      setIndex: 0,
      reps: const Value(8),
      weightKg: const Value(60.0),
    ));
    await repo.finishSession(older);

    // Newer session: a warmup then two working sets.
    final newer = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: newer,
      exerciseId: bench,
      position: 0,
      setIndex: 0,
      reps: const Value(10),
      weightKg: const Value(40.0),
      isWarmup: const Value(true),
    ));
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: newer,
      exerciseId: bench,
      position: 0,
      setIndex: 1,
      reps: const Value(8),
      weightKg: const Value(65.0),
    ));
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: newer,
      exerciseId: bench,
      position: 0,
      setIndex: 2,
      reps: const Value(6),
      weightKg: const Value(67.5),
    ));
    await repo.finishSession(newer);

    final last = await repo.lastSetFor(bench);
    expect(last, isNotNull);
    // Most recent session, last working set, warmup skipped.
    expect(last!.weightKg, 67.5);
    expect(last.reps, 6);
    expect(last.isWarmup, isFalse);
  });

  test('previousSessionSetsFor returns the last session\'s sets in order',
      () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench', category: 'strength'),
    );
    expect(await repo.previousSessionSetsFor(bench), isEmpty);

    final older = await repo.startSession(date: '2026-06-15');
    await repo.addSet(SetEntriesCompanion.insert(
        sessionId: older,
        exerciseId: bench,
        position: 0,
        setIndex: 0,
        reps: const Value(8),
        weightKg: const Value(50.0)));
    await repo.finishSession(older);

    final newer = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
        sessionId: newer,
        exerciseId: bench,
        position: 0,
        setIndex: 0,
        reps: const Value(8),
        weightKg: const Value(60.0)));
    await repo.addSet(SetEntriesCompanion.insert(
        sessionId: newer,
        exerciseId: bench,
        position: 0,
        setIndex: 1,
        reps: const Value(6),
        weightKg: const Value(62.5)));
    await repo.finishSession(newer);

    final prev = await repo.previousSessionSetsFor(bench);
    expect(prev.length, 2); // the newer session only, not the older
    expect(prev[0].weightKg, 60.0);
    expect(prev[1].weightKg, 62.5);
  });

  test('history queries ignore un-checked (completed==false) sets', () async {
    // Regression: an auto-added pending set (never checked off) must not count
    // as performed history. Only completed==true sets on a finished session
    // should be returned by setsForExercise/previousSessionSetsFor/lastSetFor.
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench', category: 'strength'),
    );
    final session = await repo.startSession(date: '2026-06-17');
    // One real (checked) set, then a phantom auto-added pending set.
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: session,
      exerciseId: bench,
      position: 0,
      setIndex: 0,
      reps: const Value(8),
      weightKg: const Value(60.0),
      completed: const Value(true),
    ));
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: session,
      exerciseId: bench,
      position: 0,
      setIndex: 1,
      reps: const Value(8),
      weightKg: const Value(60.0),
      completed: const Value(false),
    ));
    await repo.finishSession(session);

    expect((await repo.setsForExercise(bench)).length, 1);
    final prev = await repo.previousSessionSetsFor(bench);
    expect(prev.length, 1);
    expect(prev.single.completed, isTrue);
    expect((await repo.lastSetFor(bench))!.weightKg, 60.0);
  });

  test('lastSetFor ignores sets on in-progress (uncompleted) sessions',
      () async {
    final squat = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Squat', category: 'strength'),
    );
    final live = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: live,
      exerciseId: squat,
      position: 0,
      setIndex: 0,
      reps: const Value(5),
      weightKg: const Value(100.0),
    ));
    // Session not finished → not eligible history.
    expect(await repo.lastSetFor(squat), isNull);
  });

  test('updateExercise overwrites editable fields', () async {
    final id = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Cable Crunch',
      category: 'strength',
      isCustom: const Value(true),
    ));
    await repo.updateExercise(
      id,
      const ExercisesCompanion(
        name: Value('Cable Crunch (kneeling)'),
        primaryMuscle: Value('core'),
        secondaryMuscles: Value('forearms'),
        tracksWeight: Value(true),
        tracksReps: Value(true),
      ),
    );
    final e = await repo.exerciseById(id);
    expect(e!.name, 'Cable Crunch (kneeling)');
    expect(e.primaryMuscle, 'core');
    expect(e.secondaryMuscles, 'forearms');
  });

  test('duplicateAsCustom clones a built-in into an editable custom copy',
      () async {
    final builtInId = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Bench Press',
      category: 'strength',
      slug: const Value('bench-press'),
      primaryMuscle: const Value('chest'),
      secondaryMuscles: const Value('triceps,shoulders'),
      equipment: const Value('barbell'),
      description: const Value('Press the bar.'),
      tracksWeight: const Value(true),
      tracksReps: const Value(true),
    ));
    final builtIn = (await repo.exerciseById(builtInId))!;

    final copyId = await repo.duplicateAsCustom(builtIn);
    final copy = (await repo.exerciseById(copyId))!;

    expect(copy.name, 'Bench Press (custom)'); // distinct → survives dedupe
    expect(copy.isCustom, isTrue);
    expect(copy.slug, isNull);
    expect(copy.primaryMuscle, 'chest');
    expect(copy.secondaryMuscles, 'triceps,shoulders');
    expect(copy.equipment, 'barbell');
    expect(copy.tracksWeight, isTrue);
    // The built-in is untouched.
    expect((await repo.exerciseById(builtInId))!.slug, 'bench-press');
  });

  test('deleteExercise removes an unused exercise but blocks a referenced one',
      () async {
    final unused = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Unused Move',
      category: 'strength',
      isCustom: const Value(true),
    ));
    // Deletes cleanly when nothing references it.
    expect(await repo.deleteExercise(unused), isTrue);
    expect(await repo.exerciseById(unused), isNull);

    // Referenced by a logged set → blocked.
    final logged = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Logged Move',
      category: 'strength',
      isCustom: const Value(true),
    ));
    final session = await repo.startSession(date: '2026-06-17');
    await repo.addSet(SetEntriesCompanion.insert(
      sessionId: session,
      exerciseId: logged,
      position: 0,
      setIndex: 0,
      reps: const Value(10),
    ));
    expect(await repo.deleteExercise(logged), isFalse);
    expect(await repo.exerciseById(logged), isNotNull);

    // Referenced by a program day → also blocked.
    final inProgram = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Program Move',
      category: 'strength',
      isCustom: const Value(true),
    ));
    final programId = await repo.createProgram(name: 'P');
    final dayId = await repo.createDay(programId: programId, name: 'D');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: inProgram,
        position: 0,
        targetSets: const Value(3),
      ),
    ]);
    expect(await repo.deleteExercise(inProgram), isFalse);
    expect(await repo.exerciseById(inProgram), isNotNull);
  });

  test('program + day CRUD + setDayExercises round-trip', () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench Press', category: 'strength'),
    );
    final row = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Row', category: 'strength'),
    );

    final programId = await repo.createProgram(name: 'Upper', notes: 'A');
    var programs = await repo.allPrograms();
    expect(programs.length, 1);
    expect(programs.single.name, 'Upper');
    expect(programs.single.notes, 'A');

    final dayId = await repo.createDay(
      programId: programId,
      name: 'Day 1',
      position: 0,
    );
    var days = await repo.daysForProgram(programId);
    expect(days.length, 1);
    expect(days.single.name, 'Day 1');
    expect(days.single.templateId, programId);

    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(3),
        targetReps: const Value('8-12'),
      ),
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: row,
        position: 1,
        targetSets: const Value(4),
        targetReps: const Value('10'),
      ),
    ]);

    var exercises = await repo.dayExercises(dayId);
    expect(exercises.length, 2);
    expect(exercises[0].exerciseId, bench);
    expect(exercises[0].targetReps, '8-12');
    expect(exercises[1].exerciseId, row);

    // Replacing the prescription overwrites (delete-then-insert), not appends.
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(5),
      ),
    ]);
    exercises = await repo.dayExercises(dayId);
    expect(exercises.length, 1);
    expect(exercises.single.targetSets, 5);

    await repo.updateProgram(programId, name: 'Upper Body');
    expect((await repo.programById(programId))!.name, 'Upper Body');

    await repo.updateDay(dayId, name: 'Day One');
    expect((await repo.dayById(dayId))!.name, 'Day One');
  });

  test('deleteProgram cascades days, exercises, and schedule entries',
      () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench Press', category: 'strength'),
    );

    final programId = await repo.createProgram(name: 'PPL');
    final dayId = await repo.createDay(programId: programId, name: 'Push');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(3),
      ),
    ]);
    await repo.setScheduleForDay(0, [dayId]); // Monday → Push

    expect((await repo.daysForProgram(programId)).length, 1);
    expect((await repo.dayExercises(dayId)).length, 1);
    expect((await repo.scheduleForDay(0)).length, 1);

    await repo.deleteProgram(programId);

    expect(await repo.programById(programId), isNull);
    expect(await repo.daysForProgram(programId), isEmpty);
    expect(await repo.dayExercises(dayId), isEmpty);
    expect(await repo.scheduleForDay(0), isEmpty);
  });

  test('deleteDay removes its exercises + schedule entry but keeps the program',
      () async {
    final bench = await repo.insertExercise(
      ExercisesCompanion.insert(name: 'Bench Press', category: 'strength'),
    );

    final programId = await repo.createProgram(name: 'PPL');
    final dayId = await repo.createDay(programId: programId, name: 'Push');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: bench,
        position: 0,
        targetSets: const Value(3),
      ),
    ]);
    await repo.setScheduleForDay(0, [dayId]);

    await repo.deleteDay(dayId);

    expect(await repo.dayById(dayId), isNull);
    expect(await repo.dayExercises(dayId), isEmpty);
    expect(await repo.scheduleForDay(0), isEmpty);
    // The program itself survives.
    expect(await repo.programById(programId), isNotNull);
    expect(await repo.daysForProgram(programId), isEmpty);
  });
}
