import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
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

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeSpeech implements SpeechProvider {
  final List<String> spoken = [];
  String? get lastSpoken => spoken.isEmpty ? null : spoken.last;

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
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> dispose() async {}
}

class FakeLLMProvider implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async =>
      {'intent': 'unknown'};

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async =>
      throw UnimplementedError();
}

class FakeOFF extends OpenFoodFactsClient {
  final PerHundred? _result;
  FakeOFF(this._result) : super();

  @override
  Future<PerHundred?> search(String query) async => _result;
}

class FakeUSDA extends UsdaClient {
  FakeUSDA() : super(apiKey: 'fake');

  @override
  Future<PerHundred?> search(String query) async => null;
}

class FakeFoodCacheRepository implements FoodCacheRepository {
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
// Helpers
// ---------------------------------------------------------------------------

CookingSession makeSession({
  required List<String> steps,
  required FakeSpeech speech,
  required AppDatabase db,
  PerHundred? chickenPer100,
  int? recipeId,
  List<FoodMacros> cacheSeed = const [],
  Future<bool> Function(String food, double grams)? onAdjustIngredient,
  Future<void> Function()? onRecipeNutritionChanged,
}) {
  final cache = FakeFoodCacheRepository();
  for (final food in cacheSeed) {
    cache.put(food);
  }
  final logRepo = LogRepository(db);
  final targetRepo = TargetRepository(db);
  final llm = FakeLLMProvider();

  final lookup = FoodLookup(
    cache: cache,
    off: FakeOFF(chickenPer100),
    usda: FakeUSDA(),
    llm: llm,
  );

  final parser = IntentParser(llm: llm);
  final logService = DailyLogService(logs: logRepo, targets: targetRepo);

  return CookingSession(
    steps: steps,
    speech: speech,
    parser: parser,
    lookup: lookup,
    log: logService,
    date: '2026-06-14',
    recipeId: recipeId,
    onAdjustIngredient: onAdjustIngredient,
    onRecipeNutritionChanged: onRecipeNutritionChanged,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  final steps = ['Chop onions', 'Fry', 'Season and serve'];

  test('"what is next" speaks step 1 ("Chop onions")', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    // Initial step is 0. "what is next" should advance to step 1
    await session.handleUtterance('what is next');
    expect(session.currentStep.value, 1);
    expect(speech.lastSpoken, 'Fry');
  });

  test('"next" then "next" advances through steps', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    await session.handleUtterance('next');
    expect(session.currentStep.value, 1);
    expect(speech.lastSpoken, 'Fry');

    await session.handleUtterance('next');
    expect(session.currentStep.value, 2);
    expect(speech.lastSpoken, 'Season and serve');
  });

  test('"repeat" re-speaks current step', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    // Advance to step 1 ("Fry")
    await session.handleUtterance('next');
    expect(speech.lastSpoken, 'Fry');

    // Repeat should re-speak "Fry"
    await session.handleUtterance('repeat');
    expect(speech.lastSpoken, 'Fry');
    expect(session.currentStep.value, 1); // step unchanged
  });

  test('"what is next" from step 0 speaks step index 1', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    await session.handleUtterance('what is next');
    expect(speech.lastSpoken, steps[1]); // "Fry"
  });

  test('log ingredient resolves macros and spoken confirmation contains protein',
      () async {
    final speech = FakeSpeech();
    // chicken breast: 165 kcal/100g, 31g protein, 0 carb, 3.6g fat
    const chickenPer100 = PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);

    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
      chickenPer100: chickenPer100,
    );

    // 200g chicken breast → 62g protein
    await session.handleUtterance('200 grams of chicken breast');

    // Check that something was spoken
    expect(speech.spoken, isNotEmpty);
    // The confirmation should mention protein = 62
    expect(speech.lastSpoken, contains('62'));
  });

  test('spoken confirmation names the local-database source for a pack hit',
      () async {
    final speech = FakeSpeech();
    const chickenPer100 = PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);

    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
      // A cached localDb food resolves directly (no retriever/network needed),
      // exercising the same source that a real pack direct-hit produces.
      cacheSeed: const [
        FoodMacros(
          name: 'chicken breast',
          perHundred: chickenPer100,
          source: MacroSource.localDb,
          isEstimate: false,
        ),
      ],
    );

    await session.handleUtterance('200 grams of chicken breast');

    expect(speech.lastSpoken, contains('62')); // still reports the macros
    expect(speech.lastSpoken, contains('from the local database'));
  });

  test('adjustIngredient overrides the recipe ingredient and does NOT log',
      () async {
    final speech = FakeSpeech();
    final adjusted = <String, double>{};
    var recomputed = false;

    final session = makeSession(
      steps: const ['Cook the chicken'],
      speech: speech,
      db: db,
      recipeId: 42,
      onAdjustIngredient: (food, grams) async {
        adjusted[food] = grams;
        return true; // matched
      },
      onRecipeNutritionChanged: () async {
        recomputed = true;
      },
    );

    await session.handleUtterance('I used 1325g of chicken');

    expect(adjusted['chicken'], 1325);
    expect(recomputed, isTrue);
    // No daily log entry was created for this adjust.
    final totals = await session.log.totals('2026-06-14');
    expect(totals.consumed.kcal, 0);
    expect(speech.lastSpoken!.toLowerCase(), contains('chicken'));
  });

  test('adjustIngredient with no recipe match falls back to logging', () async {
    final speech = FakeSpeech();
    const chickenPer100 =
        PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);
    final session = makeSession(
      steps: const ['Cook'],
      speech: speech,
      db: db,
      chickenPer100: chickenPer100,
      recipeId: 7,
      onAdjustIngredient: (food, grams) async => false, // no match
    );

    await session.handleUtterance('I used 200g of chicken');

    // Falls back to logging -> a daily entry exists.
    final totals = await session.log.totals('2026-06-14');
    expect(totals.consumed.kcal, greaterThan(0));
  });

  test('"exit" sets exited=true and speaks goodbye', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    await session.handleUtterance('exit');
    expect(session.exited, true);
    expect(speech.lastSpoken, contains('Exiting'));
  });

  test('"stop cooking" also sets exited=true', () async {
    final speech = FakeSpeech();
    final session = makeSession(
      steps: steps,
      speech: speech,
      db: db,
    );

    await session.handleUtterance('stop cooking');
    expect(session.exited, true);
  });
}
