import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('exercise + session + set round-trip (schema v6)', () async {
    final exerciseId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: 'Back Squat',
            category: 'strength',
            slug: const Value('back-squat'),
            primaryMuscle: const Value('quads'),
            equipment: const Value('barbell'),
            tracksWeight: const Value(true),
            tracksReps: const Value(true),
          ),
        );

    final sessionId = await db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            date: '2026-06-17',
            name: 'Leg Day',
          ),
        );

    final setId = await db.into(db.setEntries).insert(
          SetEntriesCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            position: 0,
            setIndex: 0,
            reps: const Value(5),
            weightKg: const Value(100.0),
            enteredUnit: const Value('kg'),
          ),
        );

    final exercise = await (db.select(db.exercises)
          ..where((e) => e.id.equals(exerciseId)))
        .getSingle();
    expect(exercise.slug, 'back-squat');
    expect(exercise.tracksWeight, true);
    expect(exercise.tracksReps, true);
    expect(exercise.tracksDuration, false);
    expect(exercise.isCustom, false);

    final session = await (db.select(db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingle();
    expect(session.name, 'Leg Day');
    expect(session.dayId, null);

    final setEntry = await (db.select(db.setEntries)
          ..where((s) => s.id.equals(setId)))
        .getSingle();
    expect(setEntry.sessionId, sessionId);
    expect(setEntry.exerciseId, exerciseId);
    expect(setEntry.reps, 5);
    expect(setEntry.weightKg, 100.0);
    expect(setEntry.enteredUnit, 'kg');
    expect(setEntry.completed, true);
    expect(setEntry.isWarmup, false);
  });

  test('program + day + templateExercise round-trip (schema v10)', () async {
    final exerciseId = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            name: 'Bench Press',
            category: 'strength',
            slug: const Value('bench-press'),
            tracksWeight: const Value(true),
            tracksReps: const Value(true),
          ),
        );

    final programId = await db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(
            name: 'Upper/Lower (4-day)',
            notes: const Value('split'),
          ),
        );
    final dayId = await db.into(db.templateDays).insert(
          TemplateDaysCompanion.insert(
            templateId: programId,
            name: 'Upper A',
            position: const Value(0),
          ),
        );

    final teId = await db.into(db.templateExercises).insert(
          TemplateExercisesCompanion.insert(
            dayId: dayId,
            exerciseId: exerciseId,
            position: 0,
            targetSets: const Value(3),
            targetReps: const Value('8-12'),
            targetWeightKg: const Value(60.0),
          ),
        );

    final day = await (db.select(db.templateDays)
          ..where((d) => d.id.equals(dayId)))
        .getSingle();
    expect(day.templateId, programId);
    expect(day.name, 'Upper A');
    expect(day.position, 0);

    final te = await (db.select(db.templateExercises)
          ..where((t) => t.id.equals(teId)))
        .getSingle();
    expect(te.dayId, dayId);
    expect(te.exerciseId, exerciseId);
    expect(te.targetSets, 3);
    expect(te.targetReps, '8-12');
    expect(te.targetWeightKg, 60.0);
  });

  test('schedule entry round-trip (schema v10)', () async {
    final programId = await db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(name: 'Program'),
        );
    final dayId = await db.into(db.templateDays).insert(
          TemplateDaysCompanion.insert(templateId: programId, name: 'Push'),
        );

    final entryId = await db.into(db.scheduleEntries).insert(
          ScheduleEntriesCompanion.insert(
            dayOfWeek: 0, // Monday
            dayId: dayId,
            position: const Value(0),
          ),
        );

    final entry = await (db.select(db.scheduleEntries)
          ..where((s) => s.id.equals(entryId)))
        .getSingle();
    expect(entry.dayOfWeek, 0);
    expect(entry.dayId, dayId);
    expect(entry.position, 0);
  });

  // Exercises the exact SQL the v9→v10 migration runs (see database.dart
  // onUpgrade `from < 10`): each legacy template becomes a single-day program
  // whose day id equals the template id, so child FKs re-key by a
  // values-preserving column rename. Tested at the SQL level on a raw sqlite3
  // connection so the v9 schema can be built by hand.
  test('v9 → v10 migration re-keys templates to single-day programs', () {
    final raw = sqlite3.openInMemory();
    // Minimal v9 schema: the four tables the migration touches, old names.
    raw.execute('CREATE TABLE workout_templates (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, name TEXT NOT NULL, notes TEXT, position INTEGER NOT '
        'NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT 0);');
    raw.execute('CREATE TABLE template_exercises (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, template_id INTEGER NOT NULL, exercise_id INTEGER NOT '
        'NULL, position INTEGER NOT NULL);');
    raw.execute('CREATE TABLE schedule_entries (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, day_of_week INTEGER NOT NULL, template_id INTEGER NOT '
        'NULL, position INTEGER NOT NULL DEFAULT 0);');
    raw.execute('CREATE TABLE workout_sessions (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, date TEXT NOT NULL, template_id INTEGER, name TEXT NOT '
        'NULL);');
    // Legacy data: one program-day template (id 1) with a child everywhere.
    raw.execute("INSERT INTO workout_templates (id, name, notes, position, "
        "created_at) VALUES (1, 'Push Day', NULL, 0, 0);");
    raw.execute('INSERT INTO template_exercises (template_id, exercise_id, '
        'position) VALUES (1, 7, 0);');
    raw.execute('INSERT INTO schedule_entries (day_of_week, template_id, '
        'position) VALUES (0, 1, 0);');
    raw.execute("INSERT INTO workout_sessions (date, template_id, name) VALUES "
        "('2026-06-17', 1, 'Push Day');");

    // The v10 migration statements (mirror database.dart).
    raw.execute('CREATE TABLE template_days (id INTEGER PRIMARY KEY '
        'AUTOINCREMENT, template_id INTEGER NOT NULL, name TEXT NOT NULL, '
        'position INTEGER NOT NULL DEFAULT 0, notes TEXT, created_at INTEGER '
        'NOT NULL DEFAULT 0);');
    raw.execute('INSERT INTO template_days (id, template_id, name, position) '
        'SELECT id, id, name, 0 FROM workout_templates;');
    raw.execute(
        'ALTER TABLE template_exercises RENAME COLUMN template_id TO day_id;');
    raw.execute(
        'ALTER TABLE schedule_entries RENAME COLUMN template_id TO day_id;');
    raw.execute(
        'ALTER TABLE workout_sessions RENAME COLUMN template_id TO day_id;');

    // One day, id == its program-template id, same name.
    final days = raw.select('SELECT id, template_id, name FROM template_days;');
    expect(days.length, 1);
    expect(days.first['id'], 1);
    expect(days.first['template_id'], 1);
    expect(days.first['name'], 'Push Day');

    // Child rows re-keyed to day_id == 1 (values preserved).
    expect(raw.select('SELECT day_id FROM template_exercises;').first['day_id'],
        1);
    expect(
        raw.select('SELECT day_id FROM schedule_entries;').first['day_id'], 1);
    expect(
        raw.select('SELECT day_id FROM workout_sessions;').first['day_id'], 1);

    // sqlite_sequence continues past the explicit id (next insert > 1).
    raw.execute("INSERT INTO template_days (template_id, name, position) VALUES "
        "(1, 'Day 2', 1);");
    final maxId =
        raw.select('SELECT MAX(id) AS m FROM template_days;').first['m'] as int;
    expect(maxId, greaterThan(1));

    raw.dispose();
  });

  test('daily activity round-trip (schema v9)', () async {
    await db.into(db.dailyActivity).insert(
          DailyActivityCompanion.insert(
            date: '2026-06-17',
            steps: const Value(8500),
            activeMinutes: const Value(42),
          ),
        );

    final row = await (db.select(db.dailyActivity)
          ..where((a) => a.date.equals('2026-06-17')))
        .getSingle();
    expect(row.steps, 8500);
    expect(row.activeMinutes, 42);
    expect(row.source, 'manual'); // default
  });
}
