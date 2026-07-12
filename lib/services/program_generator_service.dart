import 'package:drift/drift.dart' show Value;

import '../data/database.dart';
import '../data/repositories/training_repository.dart';
import '../models/chat.dart';
import '../providers/llm/llm_provider.dart';

/// User-supplied parameters describing the training program to generate.
class ProgramRequest {
  final String goal; // e.g. "build muscle", "get stronger", "run a 5k"
  final String experience; // beginner | intermediate | advanced
  final String equipment; // e.g. "full gym", "dumbbells only", "bodyweight"
  final int daysPerWeek; // 1..7
  final int sessionMinutes; // approx session length

  const ProgramRequest({
    required this.goal,
    required this.experience,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessionMinutes,
  });
}

/// One prescribed exercise inside a generated template.
class GeneratedExercise {
  /// Name or slug as emitted by the LLM (used to match the library).
  final String nameOrSlug;
  final int? sets;
  final String? reps; // text, allows "8-12"
  final double? weightKg;
  final int? durationSec;
  final double? distanceM;

  const GeneratedExercise({
    required this.nameOrSlug,
    this.sets,
    this.reps,
    this.weightKg,
    this.durationSec,
    this.distanceM,
  });
}

/// One generated workout template (a named day's exercises).
class GeneratedTemplate {
  final String name;
  final List<GeneratedExercise> exercises;
  const GeneratedTemplate({required this.name, required this.exercises});
}

/// A fully generated program: a set of editable templates plus a weekly
/// schedule mapping `dayOfWeek` (0=Mon..6=Sun) to a template index.
class GeneratedProgram {
  /// Short name for the overall program (e.g. "4-Day Upper/Lower").
  final String name;

  final List<GeneratedTemplate> templates;

  /// dayOfWeek (0=Mon..6=Sun) → index into [templates]. Days not present are
  /// rest days.
  final Map<int, int> schedule;

  const GeneratedProgram({
    required this.name,
    required this.templates,
    required this.schedule,
  });
}

/// LLM-backed training-program generator, mirroring
/// `recipe_generator_service.dart`. Builds a prompt from a [ProgramRequest],
/// asks the [LLMProvider] for structured JSON, and parses it into a
/// [GeneratedProgram]. Persistence (mapping generated exercises onto library
/// slugs, creating custom exercises for unmatched names, and writing templates
/// + schedule) is done via [persist], which goes through [TrainingRepository].
///
/// Pure Dart — no Flutter imports.
class ProgramGeneratorService {
  final LLMProvider llm;
  ProgramGeneratorService(this.llm);

  /// Generate a structured program from [request]. Embeds the request fields in
  /// the prompt and parses the LLM's JSON response.
  Future<GeneratedProgram> generate(ProgramRequest request) async {
    final schema = {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'templates': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'exercises': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                    'sets': {'type': 'integer'},
                    'reps': {'type': 'string'},
                    'weightKg': {'type': 'number'},
                    'durationSec': {'type': 'integer'},
                    'distanceM': {'type': 'number'},
                  },
                  'required': ['name'],
                },
              },
            },
            'required': ['name', 'exercises'],
          },
        },
        'schedule': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'dayOfWeek': {'type': 'integer'},
              'templateIndex': {'type': 'integer'},
            },
            'required': ['dayOfWeek', 'templateIndex'],
          },
        },
      },
      'required': ['templates', 'schedule'],
    };

    final buf = StringBuffer()
      ..write('Design a ${request.daysPerWeek}-day-per-week training program. ')
      ..write('Goal: ${request.goal}. ')
      ..write('Experience level: ${request.experience}. ')
      ..write('Available equipment: ${request.equipment}. ')
      ..write('Each session should take about ${request.sessionMinutes} '
          'minutes. ')
      ..write('Create exactly ${request.daysPerWeek} distinct workout '
          'templates and assign each to a weekday. ')
      ..write('dayOfWeek is 0=Monday..6=Sunday; templateIndex is the 0-based '
          'index into the templates array. ')
      ..write('Spread training days through the week with rest days between '
          'them where sensible. ')
      ..write('Prefer common, well-known exercise names (e.g. "Back Squat", '
          '"Bench Press", "Running") so they map to a standard library. ')
      ..write('For strength exercises set sets and reps (reps may be a range '
          'like "8-12"); for cardio set durationSec and/or distanceM; for '
          'classes/mobility set durationSec. ')
      ..write('Also return a short "name" for the overall program. ')
      ..write('Return JSON with "name", "templates" (each: name, '
          'exercises[name, sets, reps, weightKg, durationSec, distanceM]) and '
          '"schedule" (array of {dayOfWeek, templateIndex}).');

    // A multi-day program is a large JSON payload; without a generous token
    // budget the response truncates mid-array and templates come back empty.
    final r = await llm.structured(buf.toString(), schema,
        opts: const ChatOpts(maxTokens: 6000));
    return _parse(r);
  }

  GeneratedProgram _parse(Map<String, dynamic> r) {
    final templates = ((r['templates'] as List?) ?? [])
        .whereType<Map>()
        .map((t) {
          final exercises = ((t['exercises'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => GeneratedExercise(
                    nameOrSlug: (e['name'] ?? '').toString(),
                    sets: _toIntOrNull(e['sets']),
                    reps: _toStrOrNull(e['reps']),
                    weightKg: _toDOrNull(e['weightKg']),
                    durationSec: _toIntOrNull(e['durationSec']),
                    distanceM: _toDOrNull(e['distanceM']),
                  ))
              .where((e) => e.nameOrSlug.trim().isNotEmpty)
              .toList();
          return GeneratedTemplate(
            name: (t['name'] ?? 'Workout').toString(),
            exercises: exercises,
          );
        })
        .toList();

    final schedule = <int, int>{};
    for (final s in (r['schedule'] as List?) ?? []) {
      if (s is! Map) continue;
      final day = _toIntOrNull(s['dayOfWeek']);
      final idx = _toIntOrNull(s['templateIndex']);
      if (day == null || idx == null) continue;
      if (day < 0 || day > 6) continue;
      if (idx < 0 || idx >= templates.length) continue;
      schedule[day] = idx; // one template per day; last wins
    }

    return GeneratedProgram(
      name: (r['name'] ?? 'Generated Program').toString(),
      templates: templates,
      schedule: schedule,
    );
  }

  /// Persist a (possibly user-edited) [program] through [repo]: resolve each
  /// generated exercise to a library exercise id (matching by slug or name,
  /// case-insensitive; creating a custom exercise when unmatched), create one
  /// program with a day per generated template (each carrying its prescription),
  /// then write the weekly schedule. Returns the created day ids in template
  /// order.
  Future<List<int>> persist(
    GeneratedProgram program,
    TrainingRepository repo,
  ) async {
    final existing = await repo.allExercises();
    // Lookup maps: by slug and by lowercased name.
    final bySlug = <String, Exercise>{};
    final byName = <String, Exercise>{};
    for (final e in existing) {
      final s = e.slug;
      if (s != null) bySlug[s.toLowerCase()] = e;
      byName[e.name.toLowerCase()] = e;
    }

    // Resolve every distinct generated exercise to an exercise id, creating
    // custom rows for unmatched ones (and remembering them so duplicates within
    // the same program reuse the new id).
    Future<int> resolve(GeneratedExercise ge) async {
      final key = ge.nameOrSlug.trim();
      final lower = key.toLowerCase();
      final slugified = _slugify(key);
      final match = bySlug[lower] ?? bySlug[slugified] ?? byName[lower];
      if (match != null) return match.id;
      // Create a custom exercise. Strength-ish default capability flags so the
      // logger shows weight+reps; refined later by the user.
      final id = await repo.insertExercise(ExercisesCompanion.insert(
        name: key,
        category: 'strength',
        tracksWeight: const Value(true),
        tracksReps: const Value(true),
        isCustom: const Value(true),
      ));
      final created = await repo.exerciseById(id);
      if (created != null) {
        byName[lower] = created;
        bySlug[slugified] = created;
      }
      return id;
    }

    final programId = await repo.createProgram(name: program.name);
    final dayIds = <int>[];
    for (var t = 0; t < program.templates.length; t++) {
      final template = program.templates[t];
      final dayId = await repo.createDay(
        programId: programId,
        name: template.name,
        position: t,
      );
      final companions = <TemplateExercisesCompanion>[];
      for (var i = 0; i < template.exercises.length; i++) {
        final ge = template.exercises[i];
        final exerciseId = await resolve(ge);
        companions.add(TemplateExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: exerciseId,
          position: i,
          targetSets: Value(ge.sets),
          targetReps: Value(ge.reps),
          targetWeightKg: Value(ge.weightKg),
          targetDurationSec: Value(ge.durationSec),
          targetDistanceM: Value(ge.distanceM),
        ));
      }
      await repo.setDayExercises(dayId, companions);
      dayIds.add(dayId);
    }

    // Write the weekly schedule: dayOfWeek → dayId.
    for (final entry in program.schedule.entries) {
      final idx = entry.value;
      if (idx < 0 || idx >= dayIds.length) continue;
      await repo.setScheduleForDay(entry.key, [dayIds[idx]]);
    }

    return dayIds;
  }

  static String _slugify(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static double? _toDOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static String? _toStrOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
