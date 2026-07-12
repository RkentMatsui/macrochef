import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/cooking_intent.dart';
import '../providers/llm/llm_provider.dart';
import '../providers/speech/speech_provider.dart';
import 'food_lookup.dart';
import 'intent_parser.dart';
import 'macro_calculator.dart';
import 'daily_log_service.dart';

enum SessionState { idle, listening, understanding, speaking }

class CookingSession {
  final List<String> steps;
  final SpeechProvider speech;
  final IntentParser parser;
  final FoodLookup lookup;
  final DailyLogService log;
  final String date;

  /// Optional LLM used to answer free-form questions ("how long do I boil an
  /// egg?") when the utterance isn't a recognised command. When null, the
  /// session falls back to a plain "didn't understand" reply (e.g. in tests).
  final LLMProvider? llm;

  /// Optional recipe context. When present, "I used Xg of Y" adjusts the
  /// matching ingredient instead of logging a new food.
  final int? recipeId;
  final List<String> ingredientNames;

  /// Sets ingredient [food] to [grams] (g). Returns true if an ingredient
  /// matched. Injected so the session stays free of repository imports.
  final Future<bool> Function(String food, double grams)? onAdjustIngredient;

  /// Called after a successful adjust so the UI/nutrition cache can refresh.
  final Future<void> Function()? onRecipeNutritionChanged;

  late final ValueNotifier<SessionState> state;
  late final ValueNotifier<int> currentStep;
  bool exited = false;

  CookingSession({
    required this.steps,
    required this.speech,
    required this.parser,
    required this.lookup,
    required this.log,
    required this.date,
    this.llm,
    this.recipeId,
    this.ingredientNames = const [],
    this.onAdjustIngredient,
    this.onRecipeNutritionChanged,
  }) {
    state = ValueNotifier(SessionState.idle);
    currentStep = ValueNotifier(0);
  }

  Future<void> handleUtterance(String text) async {
    state.value = SessionState.understanding;

    final intent = await parser.parse(text);

    switch (intent.type) {
      case IntentType.nextStep:
        if (currentStep.value < steps.length - 1) {
          currentStep.value++;
        }
        await _speakCurrentStep();
        break;

      case IntentType.prevStep:
        if (currentStep.value > 0) {
          currentStep.value--;
        }
        await _speakCurrentStep();
        break;

      case IntentType.repeatStep:
        await _speakCurrentStep();
        break;

      case IntentType.exit:
        exited = true;
        state.value = SessionState.idle;
        await speech.speak('Exiting cooking mode. Goodbye!');
        break;

      case IntentType.adjustIngredient:
        await _handleAdjustIngredient(intent);
        break;

      case IntentType.logIngredient:
        await _handleLogIngredient(intent);
        break;

      case IntentType.dailyTotal:
        await _handleDailyTotal();
        break;

      case IntentType.currentMacros:
        state.value = SessionState.speaking;
        await speech.speak('Current macros are not tracked in this session.');
        state.value = SessionState.idle;
        break;

      case IntentType.unknown:
        await _handleConversation(text);
        break;
    }
  }

  /// Non-command utterance: if an LLM is available, answer it conversationally
  /// as a cooking assistant and speak the reply; otherwise say we didn't
  /// understand. Keeps the recipe context so answers are relevant.
  Future<void> _handleConversation(String text) async {
    state.value = SessionState.speaking;
    final model = llm;
    if (model == null) {
      await speech.speak('Sorry, I did not understand that. Please try again.');
      state.value = SessionState.idle;
      return;
    }
    try {
      final context = steps.isNotEmpty
          ? 'The user is cooking. Recipe steps: ${steps.join(" | ")}. '
              'Current step: ${currentStep.value + 1}.'
          : 'The user is cooking and logging food.';
      // Bound the call so a stalled model (e.g. a large on-device LLM loading
      // for the first time) can't freeze the session — the catch below speaks a
      // graceful fallback on timeout.
      final answer = await model.chat([
        ChatMessage(
          'system',
          'You are a friendly, concise cooking assistant. $context '
              'Answer in 1-3 short sentences suitable to be read aloud. '
              'Plain text only, no markdown or lists.',
        ),
        ChatMessage('user', text),
      ]).timeout(const Duration(seconds: 45));
      final reply = answer.trim();
      await speech.speak(
        reply.isEmpty ? "Sorry, I didn't catch that." : reply,
      );
    } catch (e) {
      debugPrint('[COOK] conversation error: $e');
      await speech.speak("Sorry, I couldn't reach the assistant right now.");
    }
    state.value = SessionState.idle;
  }

  Future<void> _speakCurrentStep() async {
    state.value = SessionState.speaking;
    final stepIndex = currentStep.value;
    if (stepIndex >= 0 && stepIndex < steps.length) {
      await speech.speak(steps[stepIndex]);
    }
    state.value = SessionState.idle;
  }

  Future<void> _handleAdjustIngredient(CookingIntent intent) async {
    final foodName = intent.food;
    final grams = intent.grams;
    final adjust = onAdjustIngredient;

    // No recipe context (or no adjuster wired) -> fall back to logging so the
    // user still gets a useful action.
    if (foodName == null || grams == null || adjust == null) {
      await _handleLogIngredient(intent);
      return;
    }

    state.value = SessionState.speaking;
    final matched = await adjust(foodName, grams);
    if (!matched) {
      // Not an ingredient in this recipe -> log it instead.
      state.value = SessionState.idle;
      await _handleLogIngredient(intent);
      return;
    }
    await onRecipeNutritionChanged?.call();
    await speech.speak(
      'Updated $foodName to ${grams.toStringAsFixed(0)} grams in the recipe.',
    );
    state.value = SessionState.idle;
  }

  Future<void> _handleLogIngredient(CookingIntent intent) async {
    final foodName = intent.food;
    final grams = intent.grams;

    if (foodName == null || grams == null) {
      state.value = SessionState.speaking;
      await speech.speak('Could not understand the ingredient. Please try again.');
      state.value = SessionState.idle;
      return;
    }

    final foodMacros = await lookup.resolve(foodName);
    if (foodMacros == null) {
      state.value = SessionState.speaking;
      await speech.speak('Could not find nutritional info for $foodName.');
      state.value = SessionState.idle;
      return;
    }

    final macros = MacroCalculator.forGrams(foodMacros.perHundred, grams);
    await log.log(
      date,
      name: foodName,
      grams: grams,
      macros: macros,
      source: foodMacros.source,
    );

    final kcal = macros.kcal.toStringAsFixed(0);
    final protein = macros.protein.toStringAsFixed(0);
    final carb = macros.carb.toStringAsFixed(0);
    final fat = macros.fat.toStringAsFixed(0);

    state.value = SessionState.speaking;
    await speech.speak(
      'Logged ${grams.toStringAsFixed(0)}g of $foodName: '
      '$kcal calories, $protein g protein, $carb g carbs, $fat g fat.',
    );
    state.value = SessionState.idle;
  }

  Future<void> _handleDailyTotal() async {
    final totals = await log.totals(date);
    final consumed = totals.consumed;
    final kcal = consumed.kcal.toStringAsFixed(0);
    final protein = consumed.protein.toStringAsFixed(0);
    final carb = consumed.carb.toStringAsFixed(0);
    final fat = consumed.fat.toStringAsFixed(0);

    state.value = SessionState.speaking;
    await speech.speak(
      "Today's totals: $kcal calories, $protein g protein, $carb g carbs, $fat g fat.",
    );
    state.value = SessionState.idle;
  }
}
