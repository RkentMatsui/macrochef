import '../models/cooking_intent.dart';
import '../providers/llm/llm_provider.dart';

class IntentParser {
  final LLMProvider llm;

  IntentParser({required this.llm});

  static final _nextRe =
      RegExp(r"\b(next|what\s+is\s+next|what's\s+next|continue)\b",
          caseSensitive: false);
  static final _prevRe =
      RegExp(r'\b(previous|go\s+back)\b', caseSensitive: false);
  static final _repeatRe =
      RegExp(r'\b(repeat|again|say\s+that\s+again)\b', caseSensitive: false);
  static final _exitRe = RegExp(
      r'\b(exit|stop\s+cooking|quit|done\s+cooking)\b',
      caseSensitive: false);
  static final _dailyTotalRe =
      RegExp(r'(daily\s+total|total\s+today|how\s+much\s+today)',
          caseSensitive: false);
  static final _currentMacrosRe =
      RegExp(r'(current\s+macros|macros\s+so\s+far|this\s+meal)',
          caseSensitive: false);
  static final _logIngredientRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:g|grams?)\s+(?:of\s+)?(.+)',
      caseSensitive: false);
  // "I used 1325g of chicken", "used 200 g chicken" -> adjust the recipe's
  // chicken ingredient to that amount (not a new food log).
  static final _usedRe = RegExp(
      r'\b(?:i\s+)?used\s+(\d+(?:\.\d+)?)\s*(?:g|grams?)\s+(?:of\s+)?(.+)',
      caseSensitive: false);
  // "set the chicken to 1325 grams", "make it 200g of chicken"
  static final _setToRe = RegExp(
      r'\bset\s+(?:the\s+)?(.+?)\s+to\s+(\d+(?:\.\d+)?)\s*(?:g|grams?)\b',
      caseSensitive: false);
  // Explicit logging verb keeps the log path.
  static final _logVerbRe = RegExp(r'^\s*(?:log|add)\b', caseSensitive: false);

  /// Returns a CookingIntent if a regex rule matches, else null.
  CookingIntent? parseRule(String text) {
    final t = text.trim();

    if (_nextRe.hasMatch(t)) return const CookingIntent(IntentType.nextStep);
    if (_prevRe.hasMatch(t)) return const CookingIntent(IntentType.prevStep);
    if (_repeatRe.hasMatch(t)) return const CookingIntent(IntentType.repeatStep);
    if (_exitRe.hasMatch(t)) return const CookingIntent(IntentType.exit);
    if (_dailyTotalRe.hasMatch(t)) {
      return const CookingIntent(IntentType.dailyTotal);
    }
    if (_currentMacrosRe.hasMatch(t)) {
      return const CookingIntent(IntentType.currentMacros);
    }

    // "set X to N grams"
    final setMatch = _setToRe.firstMatch(t);
    if (setMatch != null) {
      final food = setMatch.group(1)!.trim();
      final grams = double.parse(setMatch.group(2)!);
      return CookingIntent(IntentType.adjustIngredient,
          food: food, grams: grams);
    }
    // "I used N g of X" - adjust, unless prefixed with an explicit log/add verb.
    final usedMatch = _usedRe.firstMatch(t);
    if (usedMatch != null && !_logVerbRe.hasMatch(t)) {
      final grams = double.parse(usedMatch.group(1)!);
      final food = usedMatch.group(2)!.trim();
      return CookingIntent(IntentType.adjustIngredient,
          food: food, grams: grams);
    }

    final logMatch = _logIngredientRe.firstMatch(t);
    if (logMatch != null) {
      final grams = double.parse(logMatch.group(1)!);
      final food = logMatch.group(2)!.trim();
      return CookingIntent(IntentType.logIngredient, food: food, grams: grams);
    }

    return null;
  }

  /// Parses text: tries rule layer first, then falls back to LLM.
  Future<CookingIntent> parse(String text) async {
    final rule = parseRule(text);
    if (rule != null) return rule;

    // Fall back to LLM structured call
    const schema = {
      'type': 'object',
      'properties': {
        'intent': {
          'type': 'string',
          'enum': [
            'nextStep',
            'prevStep',
            'repeatStep',
            'logIngredient',
            'adjustIngredient',
            'currentMacros',
            'dailyTotal',
            'exit',
            'unknown',
          ],
        },
        'food': {'type': 'string'},
        'grams': {'type': 'number'},
      },
      'required': ['intent'],
    };

    final prompt =
        'You are a cooking assistant. Classify the user utterance into one of '
        'the following intents: nextStep, prevStep, repeatStep, logIngredient, '
        'adjustIngredient, currentMacros, dailyTotal, exit, unknown. '
        'Use adjustIngredient when the user states how much of a recipe '
        'ingredient they actually used (e.g. "I used 1325g of chicken", '
        '"set the chicken to 1325 grams"); use logIngredient only when they '
        'explicitly ask to log or add a separate food.\n\nUtterance: "$text"';

    try {
      final result = await llm.structured(prompt, schema);
      final intentStr = result['intent'] as String? ?? 'unknown';
      final intentType = IntentType.values.firstWhere(
        (e) => e.name == intentStr,
        orElse: () => IntentType.unknown,
      );
      final food = result['food'] as String?;
      final gramsRaw = result['grams'];
      final grams = gramsRaw is num ? gramsRaw.toDouble() : null;
      return CookingIntent(intentType, food: food, grams: grams);
    } catch (_) {
      return const CookingIntent(IntentType.unknown);
    }
  }
}
