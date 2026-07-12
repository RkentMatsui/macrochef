import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/exercise_library.dart';
import 'package:macrochef/services/template_seed.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;
  late SettingsRepository settings;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    settings = SettingsRepository(db);
    await seedExercises(repo); // starter programs resolve slugs against this
  });
  tearDown(() => db.close());

  test('every starter-program slug exists in the exercise library', () {
    final librarySlugs = kBuiltInExercises.map((e) => e.slug).toSet();
    for (final program in kStarterPrograms) {
      for (final day in program.days) {
        for (final ex in day.exercises) {
          expect(librarySlugs, contains(ex.slug),
              reason:
                  '${program.name} / ${day.name} references unknown slug "${ex.slug}"');
        }
      }
    }
  });

  test('seeds all starter programs with their full prescription', () async {
    await seedStarterPrograms(repo, settings);

    final programs = await repo.allPrograms();
    expect(programs.length, kStarterPrograms.length);

    // Spot-check the PPL program: 6 days, Push A resolves every exercise.
    final ppl = programs.firstWhere((p) => p.name == 'Push/Pull/Legs (6-day)');
    final pplDays = await repo.daysForProgram(ppl.id);
    expect(pplDays.length, 6);

    final pushA = pplDays.firstWhere((d) => d.name == 'Push A');
    final pushAExercises = await repo.dayExercises(pushA.id);
    expect(pushAExercises.length, 6);
    expect(pushAExercises.first.targetSets, 4);
    expect(pushAExercises.first.targetReps, '6-8');

    // The duration-based plank carries durationSec, not reps.
    final fullBody = programs.firstWhere((p) => p.name == 'Full Body (3-day)');
    final fbDays = await repo.daysForProgram(fullBody.id);
    final dayB = fbDays.firstWhere((d) => d.name == 'Day B');
    final dayBExercises = await repo.dayExercises(dayB.id);
    final plank = dayBExercises.last;
    expect(plank.targetDurationSec, 45);
    expect(plank.targetReps, isNull);
  });

  test('seeding is idempotent and records seeded program keys', () async {
    await seedStarterPrograms(repo, settings);
    final firstCount = (await repo.allPrograms()).length;

    // Second call is a no-op (all keys recorded) — no duplicates.
    await seedStarterPrograms(repo, settings);
    final secondCount = (await repo.allPrograms()).length;

    expect(secondCount, firstCount);
    final seededKeys =
        (await settings.get(kSeededProgramKeysKey) ?? '').split(',').toSet();
    expect(seededKeys, containsAll(kStarterPrograms.map((p) => p.key)));
  });

  test('a deleted starter program is not re-seeded', () async {
    await seedStarterPrograms(repo, settings);
    final programs = await repo.allPrograms();
    final victim = programs.first;
    await repo.deleteProgram(victim.id);
    final afterDelete = (await repo.allPrograms()).length;

    // Re-seeding must NOT bring the deleted program back (its key is recorded).
    await seedStarterPrograms(repo, settings);
    expect((await repo.allPrograms()).length, afterDelete);
  });

  test('legacy boolean flag migrates without re-seeding the original three',
      () async {
    // Simulate an install that seeded under the old boolean-flag scheme.
    await settings.set(kStarterTemplatesSeededKey, '1');

    await seedStarterPrograms(repo, settings);

    // The 3 legacy programs are treated as already seeded; only the newer
    // bundles get created.
    final expectedNew = kStarterPrograms
        .where((p) => !kLegacyStarterKeys.contains(p.key))
        .length;
    expect((await repo.allPrograms()).length, expectedNew);

    final seededKeys =
        (await settings.get(kSeededProgramKeysKey) ?? '').split(',').toSet();
    expect(seededKeys, containsAll(kStarterPrograms.map((p) => p.key)));
  });
}
