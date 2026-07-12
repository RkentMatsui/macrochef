import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get servings => integer().withDefault(const Constant(1))();
}

class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  TextColumn get name => text()();
  TextColumn get quantity => text().nullable()();
  TextColumn get unit => text().nullable()();
}

class RecipeSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get position => integer()();
  TextColumn get stepText => text()();
}

class FoodCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get source => text()(); // off|usda|ai|manual
  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real()();
  RealColumn get carb100 => real()();
  RealColumn get fat100 => real()();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
  BoolColumn get userOverride => boolean().withDefault(const Constant(false))();
  // Typical weight in grams of one piece/unit of this food (e.g. 1 tortilla).
  // Null until estimated (AI) or set by the user. Lets piece/count-based recipe
  // quantities ("2 tortillas") be converted to grams.
  RealColumn get gramsPerPiece => real().nullable()();
  // Dietary fibre per 100g (g). Nullable — absent in older rows and some sources.
  RealColumn get fibre100 => real().nullable()();
  // Sodium per 100g (mg). Nullable.
  RealColumn get sodium100 => real().nullable()();
}

class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get foodName => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get carb => real()();
  RealColumn get fat => real()();
  // Dietary fibre for this logged serving (g). Nullable.
  RealColumn get fibre => real().nullable()();
  TextColumn get source => text()();
  IntColumn get recipeId => integer().nullable()();
}

class DailyTargetsTable extends Table {
  @override
  String get tableName => 'daily_targets';
  TextColumn get scope => text()(); // 'default' or YYYY-MM-DD
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get carb => real()();
  RealColumn get fat => real()();
  @override
  Set<Column> get primaryKey => {scope};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class GroceryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get detail => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // YYYY-MM-DD, one entry per day
  RealColumn get kg => real()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

// ---------------------------------------------------------------------------
// Training (Phase 1: foundation + ad-hoc logger)
// ---------------------------------------------------------------------------

/// Exercise library: seeded built-ins (stable [slug]) + user-created custom
/// exercises. Capability flags describe which metric columns a logged set for
/// this exercise should record (Approach A — unified flexible entry model).
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().nullable().unique()(); // built-ins only; null for custom
  TextColumn get name => text()();
  TextColumn get category => text()(); // strength|cardio|class|mobility
  TextColumn get primaryMuscle => text().nullable()();
  // Comma-separated secondary/synergist muscle keys (e.g. "triceps,shoulders").
  // Credited 0.5 sets each in the weekly hypertrophy heatmap. Null = none.
  TextColumn get secondaryMuscles => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get description => text().nullable()(); // how-to / form cues
  BoolColumn get tracksWeight => boolean().withDefault(const Constant(false))();
  BoolColumn get tracksReps => boolean().withDefault(const Constant(false))();
  BoolColumn get tracksDuration => boolean().withDefault(const Constant(false))();
  BoolColumn get tracksDistance => boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One workout session — ad-hoc (dayId == null) or day-driven.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get dayId => integer().nullable()(); // null = ad-hoc; → TemplateDays
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get perceivedEffort => integer().nullable()(); // session RPE 1-10
  TextColumn get notes => text().nullable()();
}

/// Unified logged-effort table. Metric columns are nullable; which ones are
/// populated is driven by the exercise's capability flags.
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()(); // exercise order within session
  IntColumn get setIndex => integer()(); // set number within exercise
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get durationSec => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  RealColumn get rpe => real().nullable()();
  TextColumn get enteredUnit => text().nullable()(); // 'kg'|'lb' the user typed
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get completed => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ---------------------------------------------------------------------------
// Training (Phase 2: reusable templates)
// ---------------------------------------------------------------------------

/// A program — a named collection of [TemplateDays]. (Table name retained for
/// migration safety; semantically a program, e.g. "Upper/Lower (4-day)".)
class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One named day inside a [WorkoutTemplates] program (e.g. "Upper A"). A day
/// owns an ordered list of [TemplateExercises] and is the unit the schedule and
/// sessions reference.
class TemplateDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One planned exercise within a [TemplateDays], with target prescription.
/// Targets are nullable so each training type only fills the metrics it tracks.
class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(TemplateDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().nullable()();
  TextColumn get targetReps => text().nullable()(); // allows "8-12"
  RealColumn get targetWeightKg => real().nullable()();
  IntColumn get targetDurationSec => integer().nullable()();
  RealColumn get targetDistanceM => real().nullable()();
  TextColumn get notes => text().nullable()();
}

// ---------------------------------------------------------------------------
// Training (Phase 3: weekly schedule)
// ---------------------------------------------------------------------------

/// Assigns [TemplateDays] to weekdays (0=Mon..6=Sun). A day with no rows is
/// a rest day; multiple rows per day allow more than one planned session.
class ScheduleEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayOfWeek => integer()(); // 0=Mon..6=Sun
  IntColumn get dayId => integer().references(TemplateDays, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

// ---------------------------------------------------------------------------
// Training (Phase 6: daily activity / steps)
// ---------------------------------------------------------------------------

/// Manual daily step / active-minute log. One row per day. Informational only —
/// activity NEVER changes calorie targets (no calorie add-back), it is overlaid
/// on the body-weight trend purely for context.
class DailyActivity extends Table {
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get steps => integer().nullable()();
  IntColumn get activeMinutes => integer().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column> get primaryKey => {date};
}

/// Persisted per-recipe nutrition breakdown so a recipe's macros — and the
/// source of each ingredient's estimate — aren't re-resolved through the
/// OFF→USDA→AI pipeline (which offline means slow on-device LLM estimates) on
/// every open. Recomputed only when the ingredient list changes, detected via
/// an [ingredientsHash] mismatch. One row per recipe.
class RecipeNutritionCache extends Table {
  IntColumn get recipeId => integer().references(Recipes, #id)();

  /// Signature of the ingredient list this breakdown was computed from; a
  /// mismatch against the recipe's current ingredients forces a recompute.
  TextColumn get ingredientsHash => text()();

  /// Serialized [RecipeBreakdown] (per-ingredient macros + source + totals).
  TextColumn get breakdownJson => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {recipeId};
}

@DriftDatabase(tables: [
  Recipes,
  RecipeIngredients,
  RecipeSteps,
  RecipeNutritionCache,
  FoodCache,
  LogEntries,
  DailyTargetsTable,
  Settings,
  GroceryItems,
  WeightEntries,
  Exercises,
  WorkoutSessions,
  SetEntries,
  WorkoutTemplates,
  TemplateDays,
  TemplateExercises,
  ScheduleEntries,
  DailyActivity,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? driftDatabase(name: 'macrochef'));

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(recipes, recipes.servings);
            await m.addColumn(foodCache, foodCache.userOverride);
            await m.createTable(groceryItems);
          }
          if (from < 3) {
            await m.addColumn(foodCache, foodCache.gramsPerPiece);
          }
          if (from < 4) {
            await m.createTable(weightEntries);
          }
          if (from < 5) {
            await m.addColumn(foodCache, foodCache.fibre100);
            await m.addColumn(foodCache, foodCache.sodium100);
            await m.addColumn(logEntries, logEntries.fibre);
          }
          if (from < 6) {
            await m.createTable(exercises);
            await m.createTable(workoutSessions);
            await m.createTable(setEntries);
          }
          if (from < 7) {
            await m.createTable(workoutTemplates);
            await m.createTable(templateExercises);
          }
          if (from < 8) {
            await m.createTable(scheduleEntries);
          }
          if (from < 9) {
            await m.createTable(dailyActivity);
          }
          if (from < 10) {
            // Program → Day restructure. Each legacy template becomes a
            // single-day program; the new day's id equals the template id, so
            // child FKs (templateId) are already valid dayIds — re-key by a
            // values-preserving column rename. (FK enforcement is off, so the
            // stale FK target in stored DDL is harmless.)
            await m.createTable(templateDays);
            await m.database.customStatement(
              'INSERT INTO template_days (id, template_id, name, position) '
              'SELECT id, id, name, 0 FROM workout_templates;',
            );
            await m.database.customStatement(
              'ALTER TABLE template_exercises RENAME COLUMN template_id TO day_id;',
            );
            await m.database.customStatement(
              'ALTER TABLE schedule_entries RENAME COLUMN template_id TO day_id;',
            );
            await m.database.customStatement(
              'ALTER TABLE workout_sessions RENAME COLUMN template_id TO day_id;',
            );
          }
          if (from < 11) {
            await m.addColumn(exercises, exercises.description);
          }
          if (from < 12) {
            await m.addColumn(exercises, exercises.secondaryMuscles);
          }
          if (from < 13) {
            await m.createTable(recipeNutritionCache);
          }
        },
      );
}
