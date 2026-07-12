import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/progression_service.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;
  late ProgressionService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    svc = ProgressionService(repo);
  });
  tearDown(() => db.close());

  // ---- helpers ------------------------------------------------------------

  Future<int> addExercise({
    required String slug,
    required String name,
    String category = 'strength',
    String? muscle,
    String? secondary, // comma-separated secondary muscle keys
    bool weight = true,
    bool reps = true,
    bool duration = false,
    bool distance = false,
  }) {
    return repo.insertExercise(ExercisesCompanion.insert(
      slug: Value(slug),
      name: name,
      category: category,
      primaryMuscle: Value(muscle),
      secondaryMuscles: Value(secondary),
      tracksWeight: Value(weight),
      tracksReps: Value(reps),
      tracksDuration: Value(duration),
      tracksDistance: Value(distance),
    ));
  }

  /// Start a session, add the given sets, and mark it completed.
  Future<int> completedSession(
    String date,
    int exerciseId,
    List<({int? reps, double? weightKg, int? durationSec, double? distanceM})>
        sets,
  ) async {
    final id = await repo.startSession(date: date, name: 'W');
    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];
      await repo.addSet(SetEntriesCompanion.insert(
        sessionId: id,
        exerciseId: exerciseId,
        position: 0,
        setIndex: i,
        reps: Value(s.reps),
        weightKg: Value(s.weightKg),
        durationSec: Value(s.durationSec),
        distanceM: Value(s.distanceM),
      ));
    }
    await repo.finishSession(id);
    return id;
  }

  // ---- pure math ----------------------------------------------------------

  test('epley1rm uses w*(1+reps/30); reps==1 is the weight itself', () {
    expect(ProgressionService.epley1rm(100, 5), closeTo(116.667, 1e-3));
    expect(ProgressionService.epley1rm(100, 1), 100);
    expect(ProgressionService.epley1rm(0, 8), 0);
  });

  test('setVolume is weight * reps, null-safe', () {
    final s1 = SetEntry(
      id: 1,
      sessionId: 1,
      exerciseId: 1,
      position: 0,
      setIndex: 0,
      reps: 5,
      weightKg: 100,
      durationSec: null,
      distanceM: null,
      rpe: null,
      enteredUnit: null,
      isWarmup: false,
      completed: true,
      createdAt: DateTime(2026),
    );
    expect(ProgressionService.setVolume(s1), 500);
    final s2 = SetEntry(
      id: 2,
      sessionId: 1,
      exerciseId: 1,
      position: 0,
      setIndex: 1,
      reps: null,
      weightKg: null,
      durationSec: 60,
      distanceM: null,
      rpe: null,
      enteredUnit: null,
      isWarmup: false,
      completed: true,
      createdAt: DateTime(2026),
    );
    expect(ProgressionService.setVolume(s2), 0);
  });

  // ---- series -------------------------------------------------------------

  test('exerciseSeries: per-session best 1RM, top-set weight, total volume',
      () async {
    final bench = await addExercise(slug: 'bench', name: 'Bench');
    // Day 1: two sets — top set 100x5 (1RM 116.67), volume 100*5 + 90*5 = 950.
    await completedSession('2026-06-01', bench, [
      (reps: 5, weightKg: 90, durationSec: null, distanceM: null),
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null),
    ]);
    // Day 2: one set — 105x5 (1RM 122.5), volume 525.
    await completedSession('2026-06-08', bench, [
      (reps: 5, weightKg: 105, durationSec: null, distanceM: null),
    ]);

    final series = await svc.exerciseSeries(bench);
    expect(series.length, 2);
    expect(series[0].date, '2026-06-01');
    expect(series[0].topSetWeightKg, 100);
    expect(series[0].best1rm, closeTo(116.667, 1e-3));
    expect(series[0].totalVolume, 950);
    expect(series[1].date, '2026-06-08');
    expect(series[1].topSetWeightKg, 105);
    expect(series[1].best1rm, closeTo(122.5, 1e-3));
    expect(series[1].totalVolume, 525);
  });

  test('detectPrs fires on an increased top set / est-1RM', () async {
    final squat = await addExercise(slug: 'squat', name: 'Squat');
    await completedSession('2026-06-01', squat, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null),
    ]);
    // Same load — no new PR.
    await completedSession('2026-06-08', squat, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null),
    ]);
    // Heavier — new weight PR and new est-1RM PR.
    await completedSession('2026-06-15', squat, [
      (reps: 5, weightKg: 110, durationSec: null, distanceM: null),
    ]);

    final prs = await svc.detectPrs(squat);
    // First session establishes baselines (1 weight + 1 e1rm); the 110 set adds
    // one weight PR and one est-1RM PR. The middle session adds none.
    final weightPrs = prs.where((p) => p.kind == PrKind.weight).toList();
    final e1rmPrs = prs.where((p) => p.kind == PrKind.estimated1rm).toList();
    expect(weightPrs.length, 2);
    expect(e1rmPrs.length, 2);
    expect(weightPrs.last.value, 110);
    expect(weightPrs.last.date, '2026-06-15');
  });

  test('weeklyVolumeByMuscle sums volume grouped by primaryMuscle', () async {
    final bench =
        await addExercise(slug: 'bench', name: 'Bench', muscle: 'chest');
    final fly = await addExercise(slug: 'fly', name: 'Fly', muscle: 'chest');
    final row =
        await addExercise(slug: 'row', name: 'Row', muscle: 'back');
    // Week of Monday 2026-06-15.
    await completedSession('2026-06-15', bench, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
    ]);
    await completedSession('2026-06-16', fly, [
      (reps: 10, weightKg: 20, durationSec: null, distanceM: null), // 200
    ]);
    await completedSession('2026-06-17', row, [
      (reps: 8, weightKg: 60, durationSec: null, distanceM: null), // 480
    ]);
    // Outside the week — must be excluded.
    await completedSession('2026-06-08', bench, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null),
    ]);

    final byMuscle =
        await svc.weeklyVolumeByMuscle(DateTime(2026, 6, 17));
    expect(byMuscle['chest'], 700); // 500 + 200
    expect(byMuscle['back'], 480);
    expect(byMuscle.containsKey('back'), true);
  });

  test('weeklyMuscleBreakdown aggregates volume, sets, last-trained, exercises',
      () async {
    final bench =
        await addExercise(slug: 'bench', name: 'Bench', muscle: 'chest');
    final fly = await addExercise(slug: 'fly', name: 'Fly', muscle: 'chest');
    final row = await addExercise(slug: 'row', name: 'Row', muscle: 'back');
    // Week of Monday 2026-06-15.
    await completedSession('2026-06-15', bench, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
    ]);
    await completedSession('2026-06-17', fly, [
      (reps: 10, weightKg: 20, durationSec: null, distanceM: null), // 200
    ]);
    await completedSession('2026-06-16', row, [
      (reps: 8, weightKg: 60, durationSec: null, distanceM: null), // 480
    ]);
    // Outside the week — excluded.
    await completedSession('2026-06-08', bench, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null),
    ]);

    final bd = await svc.weeklyMuscleBreakdown(DateTime(2026, 6, 17));

    final chest = bd['chest']!;
    expect(chest.volume, 1200); // 1000 bench + 200 fly
    expect(chest.sets, 3);
    expect(chest.lastTrained, '2026-06-17'); // fly is the latest
    // Exercises sorted by descending volume: Bench (1000) before Fly (200).
    expect(chest.exercises.map((e) => e.name).toList(), ['Bench', 'Fly']);
    expect(chest.exercises.first.volume, 1000);
    expect(chest.exercises.first.sets, 2);

    final back = bd['back']!;
    expect(back.volume, 480);
    expect(back.sets, 1);
    expect(back.lastTrained, '2026-06-16');
  });

  test('weeklyMuscleBreakdown credits secondary muscles 0.5 sets each',
      () async {
    // Bench press: primary chest, secondaries triceps + shoulders.
    final bench = await addExercise(
        slug: 'bench',
        name: 'Bench',
        muscle: 'chest',
        secondary: 'triceps,shoulders');
    await completedSession('2026-06-15', bench, [
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
      (reps: 5, weightKg: 100, durationSec: null, distanceM: null), // 500
    ]);

    final bd = await svc.weeklyMuscleBreakdown(DateTime(2026, 6, 17));

    // Chest = primary → 3 full sets, full volume.
    expect(bd['chest']!.sets, 3.0);
    expect(bd['chest']!.volume, 1500);
    // Triceps + shoulders = secondary → 0.5 each per set = 1.5 sets, half vol.
    expect(bd['triceps']!.sets, 1.5);
    expect(bd['triceps']!.volume, 750);
    expect(bd['shoulders']!.sets, 1.5);
    expect(bd['shoulders']!.volume, 750);
    // Secondary muscles surface even though no exercise lists them as primary.
    expect(bd['triceps']!.exercises.first.name, 'Bench');
    expect(bd['triceps']!.exercises.first.sets, 1.5);
  });

  test('weeklyMuscleBreakdown counts load-free bodyweight/timed sets',
      () async {
    // Hanging leg raise: bodyweight (no weight), reps only, primary = core.
    // Regression: a zero-volume set used to be dropped, so core never showed.
    final hlr = await addExercise(
      slug: 'hanging-leg-raise',
      name: 'Hanging Leg Raise',
      category: 'mobility',
      muscle: 'core',
      weight: false,
      reps: true,
    );
    await completedSession('2026-06-15', hlr, [
      (reps: 12, weightKg: null, durationSec: null, distanceM: null),
      (reps: 12, weightKg: null, durationSec: null, distanceM: null),
      (reps: 10, weightKg: null, durationSec: null, distanceM: null),
    ]);
    // A plank (timed, no reps/weight) should also credit its muscle.
    final plank = await addExercise(
      slug: 'plank',
      name: 'Plank',
      category: 'mobility',
      muscle: 'core',
      weight: false,
      reps: false,
      duration: true,
    );
    await completedSession('2026-06-16', plank, [
      (reps: null, weightKg: null, durationSec: 60, distanceM: null),
    ]);
    // An empty (unperformed) row must still be ignored.
    await completedSession('2026-06-16', hlr, [
      (reps: null, weightKg: null, durationSec: null, distanceM: null),
    ]);

    final bd = await svc.weeklyMuscleBreakdown(DateTime(2026, 6, 17));
    expect(bd['core'], isNotNull);
    expect(bd['core']!.sets, closeTo(4, 1e-9)); // 3 leg-raise + 1 plank
    expect(bd['core']!.volume, 0); // no external load
    expect(bd['core']!.exercises.map((e) => e.name).toSet(),
        {'Hanging Leg Raise', 'Plank'});
  });

  test('consistency reports sessions/week and current streak', () async {
    final ex = await addExercise(slug: 'x', name: 'X');
    // Three consecutive weeks with a session ending on the reference week.
    await completedSession('2026-06-01', ex, [
      (reps: 5, weightKg: 50, durationSec: null, distanceM: null),
    ]);
    await completedSession('2026-06-08', ex, [
      (reps: 5, weightKg: 50, durationSec: null, distanceM: null),
    ]);
    await completedSession('2026-06-15', ex, [
      (reps: 5, weightKg: 50, durationSec: null, distanceM: null),
    ]);

    final stats =
        await svc.consistency(now: DateTime(2026, 6, 17), weeks: 4);
    expect(stats.totalSessions, 3);
    expect(stats.currentStreakWeeks, 3);
    expect(stats.sessionsPerWeek, closeTo(0.75, 1e-9)); // 3 / 4
  });

  test('cardioSeries yields distance and pace per session', () async {
    final run = await addExercise(
      slug: 'run',
      name: 'Run',
      category: 'cardio',
      weight: false,
      reps: false,
      duration: true,
      distance: true,
    );
    // 5 km in 1500 s → pace 300 s/km.
    await completedSession('2026-06-01', run, [
      (reps: null, weightKg: null, durationSec: 1500, distanceM: 5000),
    ]);

    final series = await svc.cardioSeries(run);
    expect(series.length, 1);
    expect(series.first.distanceM, 5000);
    expect(series.first.durationSec, 1500);
    expect(series.first.paceSecPerKm, closeTo(300, 1e-6));
  });
}
