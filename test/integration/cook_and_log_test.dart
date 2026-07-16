// Integration smoke test: parse recipe → cook → log ingredient → verify totals.
//
// No network, no native speech. Fakes:
//   - FakeLlm:  returns a fixed recipe map for recipe schema (has 'title' key),
//               returns fixed macros map for food schema (has 'kcal' key).
//   - FakeSpeech: captures spoken text; listening stubs are no-ops.
//   - FakeOFF:  returns chicken breast per-100g data so food lookup uses the
//               OFF code path (source = MacroSource.off, isEstimate = false).
//   - FakeUSDA: always returns null.
//   - FakeFoodCache: in-memory map (no real DB for this).
//
// Real components wired on an in-memory Drift database:
//   RecipeRepository, LogRepository, TargetRepository,
//   RecipeService, IntentParser, FoodLookup, DailyLogService, CookingSession.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/providers/speech/speech_provider.dart';
import 'package:macrochef/services/cooking_session.dart';
import 'package:macrochef/services/daily_log_service.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/intent_parser.dart';
import 'package:macrochef/services/recipe_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Distinguishes recipe schema (contains 'title') from macro schema (contains
/// 'kcal') and returns deterministic data for each.
class FakeLlm implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async => '';

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    final props = jsonSchema['properties'] as Map<String, dynamic>? ?? {};
    if (props.containsKey('title')) {
      // Recipe parse call
      return {
        'title': 'Test Curry',
        'ingredients': [
          {'name': 'chicken breast', 'quantity': '200', 'unit': 'g'},
        ],
        'steps': ['Chop onions', 'Fry chicken', 'Serve'],
      };
    }
    if (props.containsKey('kcal')) {
      // Food macro estimate call (fallback — not reached in this test because
      // FakeOFF returns a result first)
      return {'kcal': 165, 'protein': 31, 'carb': 0, 'fat': 3.6};
    }
    // IntentParser LLM fallback (not reached; regex handles all utterances)
    return {'intent': 'unknown'};
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async => throw UnimplementedError();
}

class FakeSpeech implements SpeechProvider {
  final List<String> spoken = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> startListening(
    void Function(String partial) onPartial,
    void Function(String finalText) onFinal, {
    void Function()? onSpeechEnd,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> dispose() async {}
}

/// Returns chicken breast nutrition data — keeps food lookup on the OFF path.
class FakeOFF extends OpenFoodFactsClient {
  FakeOFF() : super();

  @override
  Future<PerHundred?> search(String query) async =>
      const PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);

  @override
  Future<FoodMacros?> searchFood(String query) async => const FoodMacros(
    name: 'chicken breast',
    perHundred: PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6),
    source: MacroSource.off,
    isEstimate: false,
  );
}

class FakeUSDA extends UsdaClient {
  FakeUSDA() : super(apiKey: 'fake');

  @override
  Future<PerHundred?> search(String query) async => null;
}

class FakeFoodCache implements FoodCacheRepository {
  final Map<String, FoodMacros> _store = {};

  @override
  Future<FoodMacros?> find(String name) async => _store[name.toLowerCase()];

  @override
  Future<void> put(FoodMacros m) async => _store[m.name.toLowerCase()] = m;

  @override
  Future<void> upsertOverride(FoodMacros m) async =>
      _store[m.name.toLowerCase()] = m;

  @override
  Future<List<FoodMacros>> listOverrides() async => [];

  @override
  Future<void> deleteByName(String name) async =>
      _store.remove(name.toLowerCase());

  @override
  Future<int> clearNonOverrides() async {
    final n = _store.length;
    _store.clear();
    return n;
  }

  @override
  Future<void> setGramsPerPiece(String name, double grams) async {}

  @override
  Future<List<FoodMacros>> search(String query, {int limit = 8}) async => [];

  @override
  AppDatabase get db => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'cook-and-log: parse recipe, step through session, log ingredient, verify totals',
    () async {
      // -----------------------------------------------------------------------
      // 1. Wire up real repositories on in-memory DB
      // -----------------------------------------------------------------------
      final recipeRepo = RecipeRepository(db);
      final logRepo = LogRepository(db);
      final targetRepo = TargetRepository(db);

      // -----------------------------------------------------------------------
      // 2. Parse and save the recipe via RecipeService
      // -----------------------------------------------------------------------
      final fakeLlm = FakeLlm();
      const recipeService = RecipeService();

      final parsed = await recipeService.parse(
        'Test Curry: 200g chicken breast. Chop onions. Fry chicken. Serve.',
        fakeLlm,
      );

      expect(parsed.title, 'Test Curry');
      expect(parsed.steps, hasLength(3));

      final recipeId = await recipeService.save(parsed, recipeRepo);
      final savedSteps = await recipeRepo.stepsFor(recipeId);
      expect(savedSteps, ['Chop onions', 'Fry chicken', 'Serve']);

      // -----------------------------------------------------------------------
      // 3. Build a CookingSession from the saved steps
      //    Food lookup path: OFF → returns chicken data (source = off)
      // -----------------------------------------------------------------------
      final speech = FakeSpeech();
      final logService = DailyLogService(logs: logRepo, targets: targetRepo);

      final lookup = FoodLookup(
        cache: FakeFoodCache(),
        off: FakeOFF(),
        usda: FakeUSDA(),
        llm: fakeLlm,
      );

      final parser = IntentParser(llm: fakeLlm);

      final session = CookingSession(
        steps: savedSteps,
        speech: speech,
        parser: parser,
        lookup: lookup,
        log: logService,
        date: '2026-06-14',
      );

      // Session starts at step 0
      expect(session.currentStep.value, 0);

      // -----------------------------------------------------------------------
      // 4. "next" → advances to step 1
      //    Regex _nextRe matches "next" — no LLM call needed.
      // -----------------------------------------------------------------------
      await session.handleUtterance('next');
      expect(session.currentStep.value, 1);
      expect(speech.spoken.last, 'Fry chicken');

      // -----------------------------------------------------------------------
      // 5. "I used 200 grams of chicken breast" → resolves macros and logs
      //    Regex _logIngredientRe matches "200 grams of chicken breast" within
      //    the utterance. No LLM call needed. OFF returns 165 kcal/100g.
      //    200 g → 330 kcal, 62 g protein, 0 g carb, 7.2 g fat.
      // -----------------------------------------------------------------------
      await session.handleUtterance('I used 200 grams of chicken breast');

      // The session should have spoken a confirmation
      expect(speech.spoken, hasLength(greaterThan(1)));

      // -----------------------------------------------------------------------
      // 6. Assert the log entry
      // -----------------------------------------------------------------------
      final entries = await logRepo.forDate('2026-06-14');
      expect(entries, hasLength(1));

      final entry = entries.first;
      expect(entry.foodName, 'chicken breast');
      expect(entry.grams, closeTo(200, 0.001));
      expect(entry.kcal, closeTo(330, 0.001));
      expect(entry.protein, closeTo(62, 0.001));
      expect(entry.carb, closeTo(0, 0.001));
      expect(entry.fat, closeTo(7.2, 0.001));
      expect(entry.source, 'off');

      // -----------------------------------------------------------------------
      // 7. Assert DailyLogService.totals()
      // -----------------------------------------------------------------------
      final totals = await logService.totals('2026-06-14');
      expect(totals.consumed.kcal, closeTo(330, 0.001));
      expect(totals.consumed.protein, closeTo(62, 0.001));
      expect(totals.consumed.carb, closeTo(0, 0.001));
      expect(totals.consumed.fat, closeTo(7.2, 0.001));
    },
  );
}
