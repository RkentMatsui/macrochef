import '../models/workout_intent.dart';
import '../providers/llm/llm_provider.dart';

/// Two-layer NL -> workout intent parser. The regex layer (with a word-number
/// normalizer) owns the entire offline critical path; the LLM structured call
/// is a fallback only for utterances the rules can't classify.
class WorkoutIntentParser {
  final LLMProvider llm;
  WorkoutIntentParser({required this.llm});

  // ---- word-number normalizer -------------------------------------------

  static const Map<String, int> _ones = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
    'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
  };
  static const Map<String, int> _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
    'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  /// Replace spelled-out numbers (0-999) with digit strings, so the digit-based
  /// metric regexes match spoken transcriptions like "eighty kilos".
  static String normalizeNumbers(String input) {
    final tokens = input.toLowerCase().split(RegExp(r'\s+'));
    final out = <String>[];
    int i = 0;
    while (i < tokens.length) {
      final t = tokens[i];
      int? value;
      if (_tens.containsKey(t)) {
        value = _tens[t]!;
        // optional ones word: "twenty five"
        if (i + 1 < tokens.length && _ones.containsKey(tokens[i + 1]) &&
            _ones[tokens[i + 1]]! < 10) {
          value += _ones[tokens[i + 1]]!;
          i++;
        }
      } else if (_ones.containsKey(t)) {
        value = _ones[t]!;
      }
      if (value != null) {
        // optional "hundred" multiplier: "one hundred", "two hundred"
        if (i + 1 < tokens.length && tokens[i + 1] == 'hundred') {
          value *= 100;
          i++;
          if (i + 1 < tokens.length && _tens.containsKey(tokens[i + 1])) {
            var rest = _tens[tokens[i + 1]]!;
            i++;
            if (i + 1 < tokens.length && _ones.containsKey(tokens[i + 1]) &&
                _ones[tokens[i + 1]]! < 10) {
              rest += _ones[tokens[i + 1]]!;
              i++;
            }
            value += rest;
          } else if (i + 1 < tokens.length && _ones.containsKey(tokens[i + 1])) {
            value += _ones[tokens[i + 1]]!;
            i++;
          }
        }
        out.add('$value');
      } else if (t == 'hundred') {
        out.add('100');
      } else {
        out.add(t);
      }
      i++;
    }
    return out.join(' ');
  }

  // ---- regex layer ------------------------------------------------------

  static final _exitRe =
      RegExp(r'\b(quit|cancel workout|stop workout|exit)\b', caseSensitive: false);
  static final _finishRe = RegExp(
      r'\b(finish workout|end workout|finish|complete workout|workout done)\b',
      caseSensitive: false);
  // Anchored to the start of the utterance so conversational mentions of rest
  // ("I need to rest", "rest day tomorrow") don't silently start a timer; only
  // a leading "rest"/"timer"/"start rest" command triggers it.
  static final _restRe = RegExp(
      r'^\s*(?:start\s+)?(?:rest(?:ing)?|timer)\b(?:.*?(\d+(?:\.\d+)?)\s*(min|mins|minute|minutes|sec|secs|second|seconds)?)?',
      caseSensitive: false);
  static final _nextExerciseRe = RegExp(
      r'\bnext\s+(exercise|workout|movement|move|one|lift)\b',
      caseSensitive: false);
  static final _moveOnRe =
      RegExp(r'\b(move on|skip exercise|skip this)\b', caseSensitive: false);
  static final _commitRe = RegExp(
      r'\b(next set|done|log it|log set|got it|next)\b',
      caseSensitive: false);
  static final _prevRe = RegExp(
      r'\b(previous exercise|previous|go back|last exercise)\b',
      caseSensitive: false);
  static final _repeatRe =
      RegExp(r'\b(repeat|say again|say that again|again)\b', caseSensitive: false);
  static final _currentRe = RegExp(
      r"(what'?s next|what is next|current exercise|what am i (doing|on)|which exercise)",
      caseSensitive: false);
  static final _selectRe = RegExp(
      r'\b(?:start|begin|switch to|do)\s+(.+)',
      caseSensitive: false);
  static final _progressRe = RegExp(
      r'(how many sets|sets left|sets remaining|how many left|what set am i)',
      caseSensitive: false);
  static final _targetRe = RegExp(
      r"(what'?s the target|the target|how many should i|what weight should)",
      caseSensitive: false);
  static final _lastTimeRe = RegExp(
      r'(last time|did i do last|previous numbers|what did i lift)',
      caseSensitive: false);

  // metric sub-patterns (run on normalized text)
  static final _repsRe =
      RegExp(r'(\d+)\s*(?:reps?|times)', caseSensitive: false);
  static final _kgRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilo|kilos|kilogram|kilograms)\b',
      caseSensitive: false);
  static final _lbRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:lb|lbs|pound|pounds)\b',
      caseSensitive: false);
  static final _minRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:min|mins|minute|minutes)\b',
      caseSensitive: false);
  static final _secRe = RegExp(
      r'(\d+)\s*(?:sec|secs|second|seconds)\b',
      caseSensitive: false);
  static final _kmRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:km|kilometer|kilometers|kilometre|kilometres)\b',
      caseSensitive: false);
  static final _meterRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:meter|meters|metre|metres)\b',
      caseSensitive: false);
  static final _rpeRe =
      RegExp(r'rpe\s*(\d+(?:\.\d+)?)', caseSensitive: false);

  /// Returns a WorkoutIntent if a rule matches, else null. Checked in priority
  /// order so specific phrases win over generic ones.
  WorkoutIntent? parseRule(String raw) {
    final norm = normalizeNumbers(raw.trim());

    if (_exitRe.hasMatch(norm)) return const WorkoutIntent(WorkoutIntentType.exit);
    if (_finishRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.finishWorkout);
    }
    // rest before duration metric, so "rest 90 seconds" isn't read as a set.
    final restM = _restRe.firstMatch(norm);
    if (restM != null) {
      int? secs;
      final numStr = restM.group(1);
      if (numStr != null) {
        final n = double.parse(numStr);
        final unit = restM.group(2)?.toLowerCase();
        secs = (unit != null && unit.startsWith('min')) ? (n * 60).round() : n.round();
      }
      return WorkoutIntent(WorkoutIntentType.startRest, seconds: secs);
    }
    if (_nextExerciseRe.hasMatch(norm) || _moveOnRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.nextExercise);
    }
    if (_prevRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.prevExercise);
    }
    if (_currentRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.currentExercise);
    }
    if (_progressRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.progressQuery);
    }
    if (_targetRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.targetQuery);
    }
    if (_lastTimeRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.lastTime);
    }

    // metrics: gather any numeric fields present.
    final metric = _parseMetrics(norm);
    if (metric != null) return metric;

    if (_commitRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.commitSet);
    }
    if (_repeatRe.hasMatch(norm)) {
      return const WorkoutIntent(WorkoutIntentType.repeatExercise);
    }
    final sel = _selectRe.firstMatch(norm);
    if (sel != null) {
      return WorkoutIntent(WorkoutIntentType.selectExercise,
          exerciseName: sel.group(1)!.trim());
    }
    return null;
  }

  WorkoutIntent? _parseMetrics(String norm) {
    int? reps;
    double? weight;
    String? unit;
    int? durationSec;
    double? distanceM;
    double? rpe;

    final repsM = _repsRe.firstMatch(norm);
    if (repsM != null) reps = int.parse(repsM.group(1)!);

    final kgM = _kgRe.firstMatch(norm);
    final lbM = _lbRe.firstMatch(norm);
    if (kgM != null) {
      weight = double.parse(kgM.group(1)!);
      unit = 'kg';
    } else if (lbM != null) {
      weight = double.parse(lbM.group(1)!);
      unit = 'lb';
    }

    final minM = _minRe.firstMatch(norm);
    final secM = _secRe.firstMatch(norm);
    if (minM != null) {
      durationSec = (double.parse(minM.group(1)!) * 60).round();
    } else if (secM != null) {
      durationSec = int.parse(secM.group(1)!);
    }

    final kmM = _kmRe.firstMatch(norm);
    final mM = _meterRe.firstMatch(norm);
    if (kmM != null) {
      distanceM = double.parse(kmM.group(1)!) * 1000;
    } else if (mM != null) {
      distanceM = double.parse(mM.group(1)!);
    }

    final rpeM = _rpeRe.firstMatch(norm);
    if (rpeM != null) rpe = double.parse(rpeM.group(1)!);

    if (reps == null &&
        weight == null &&
        durationSec == null &&
        distanceM == null &&
        rpe == null) {
      return null;
    }
    return WorkoutIntent(
      WorkoutIntentType.setMetrics,
      reps: reps,
      weight: weight,
      unit: unit,
      durationSec: durationSec,
      distanceM: distanceM,
      rpe: rpe,
    );
  }

  // ---- LLM fallback -----------------------------------------------------

  Future<WorkoutIntent> parse(String text) async {
    final rule = parseRule(text);
    if (rule != null) return rule;

    const schema = {
      'type': 'object',
      'properties': {
        'intent': {
          'type': 'string',
          'enum': [
            'nextExercise', 'prevExercise', 'repeatExercise', 'currentExercise',
            'selectExercise', 'setMetrics', 'commitSet', 'progressQuery',
            'targetQuery', 'lastTime', 'startRest', 'finishWorkout', 'exit',
            'unknown',
          ],
        },
        'exerciseName': {'type': 'string'},
        'reps': {'type': 'number'},
        'weight': {'type': 'number'},
        'unit': {'type': 'string'},
        'durationSec': {'type': 'number'},
        'distanceM': {'type': 'number'},
        'rpe': {'type': 'number'},
        'seconds': {'type': 'number'},
      },
      'required': ['intent'],
    };

    final prompt =
        'You are a gym workout assistant. Classify the user utterance into one '
        'of the intents and extract any numbers. Utterance: "$text"';

    try {
      final r = await llm.structured(prompt, schema);
      final type = WorkoutIntentType.values.firstWhere(
        (e) => e.name == (r['intent'] as String? ?? 'unknown'),
        orElse: () => WorkoutIntentType.unknown,
      );
      double? d(dynamic v) => v is num ? v.toDouble() : null;
      int? n(dynamic v) => v is num ? v.toInt() : null;
      return WorkoutIntent(
        type,
        exerciseName: r['exerciseName'] as String?,
        reps: n(r['reps']),
        weight: d(r['weight']),
        unit: r['unit'] as String?,
        durationSec: n(r['durationSec']),
        distanceM: d(r['distanceM']),
        rpe: d(r['rpe']),
        seconds: n(r['seconds']),
      );
    } catch (_) {
      return const WorkoutIntent(WorkoutIntentType.unknown);
    }
  }
}
