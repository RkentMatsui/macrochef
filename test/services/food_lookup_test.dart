import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/database.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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
  Future<void> setGramsPerPiece(String name, double grams) async {
    final m = _store[name.toLowerCase()];
    if (m != null) {
      _store[name.toLowerCase()] = FoodMacros(
        name: m.name,
        perHundred: m.perHundred,
        source: m.source,
        isEstimate: m.isEstimate,
        gramsPerPiece: grams,
      );
    }
  }

  @override
  Future<List<FoodMacros>> search(String query, {int limit = 8}) async => [];

  // AppDatabase not needed for fakes — cast needed to satisfy interface
  @override
  AppDatabase get db => throw UnimplementedError();
}

class FakeOpenFoodFactsClient extends OpenFoodFactsClient {
  final PerHundred? _result;
  FakeOpenFoodFactsClient(this._result) : super();

  @override
  Future<PerHundred?> search(String query) async => _result;
}

class FakeUsdaClient extends UsdaClient {
  final PerHundred? _result;
  FakeUsdaClient(this._result) : super(apiKey: 'fake');

  @override
  Future<PerHundred?> search(String query) async => _result;
}

class FakeLLMProvider implements LLMProvider {
  Map<String, dynamic> response;
  int callCount = 0;

  FakeLLMProvider(this.response);

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    callCount++;
    return response;
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    callCount++;
    return response;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const chickenPerHundred =
      PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);

  test('cache hit short-circuits all other lookups', () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(const FoodMacros(
      name: 'chicken',
      perHundred: chickenPerHundred,
      source: MacroSource.manual,
      isEstimate: false,
    ));

    final llm = FakeLLMProvider({});
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );

    final result = await lookup.resolve('chicken');
    expect(result, isNotNull);
    expect(result!.source, MacroSource.manual);
    expect(llm.callCount, 0);
  });

  test('OFF hit is cached with isEstimate=false and source=off', () async {
    final cache = FakeFoodCacheRepository();
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(chickenPerHundred),
      usda: FakeUsdaClient(null),
      llm: FakeLLMProvider({}),
    );

    final result = await lookup.resolve('chicken breast');
    expect(result, isNotNull);
    expect(result!.source, MacroSource.off);
    expect(result.isEstimate, false);
    expect(result.perHundred.kcal, closeTo(165, 0.01));

    // Should now be in cache
    final cached = await cache.find('chicken breast');
    expect(cached, isNotNull);
    expect(cached!.source, MacroSource.off);
  });

  test('all-miss falls back to AI estimate with source=ai and isEstimate=true',
      () async {
    final cache = FakeFoodCacheRepository();
    final llm = FakeLLMProvider({
      'kcal': 165.0,
      'protein': 31.0,
      'carb': 0.0,
      'fat': 3.6,
    });

    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );

    final result = await lookup.resolve('unknown food xyz');
    expect(result, isNotNull);
    expect(result!.source, MacroSource.ai);
    expect(result.isEstimate, true);
    expect(llm.callCount, 1);
  });

  test('exception during lookup returns null', () async {
    final cache = FakeFoodCacheRepository();
    final throwingLookup = _ThrowingFoodLookup(cache: cache);
    final result = await throwingLookup.resolve('error food');
    expect(result, isNull);
  });

  test('USDA is preferred over OFF when a USDA key is set', () async {
    const usdaPer = PerHundred(kcal: 120, protein: 23, carb: 0, fat: 2.6);
    const offPer = PerHundred(kcal: 100, protein: 21, carb: 0.5, fat: 1.6);
    final cache = FakeFoodCacheRepository();
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(offPer),
      usda: FakeUsdaClient(usdaPer),
      llm: FakeLLMProvider({}),
      usdaKey: 'real-key',
    );

    final r = await lookup.resolve('chicken breast');
    expect(r!.source, MacroSource.usda);
    expect(r.perHundred.kcal, closeTo(120, 0.01));
  });

  test('implausible OFF result (>100 g carb/100 g) is rejected, falls to AI',
      () async {
    const junkOff = PerHundred(kcal: 0, protein: 0, carb: 167, fat: 0);
    final cache = FakeFoodCacheRepository();
    final llm = FakeLLMProvider({
      'kcal': 251.0,
      'protein': 10.0,
      'carb': 64.0,
      'fat': 0.0,
    });
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(junkOff),
      usda: FakeUsdaClient(null),
      llm: llm,
    );

    final r = await lookup.resolve('black pepper');
    expect(r!.source, MacroSource.ai);
    expect(llm.callCount, 1);
  });

  test('estimatePieceWeight asks the LLM and remembers it on the food',
      () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(const FoodMacros(
      name: 'tortilla',
      perHundred: PerHundred(kcal: 310, protein: 8, carb: 50, fat: 8),
      source: MacroSource.usda,
      isEstimate: false,
    ));
    final llm = FakeLLMProvider({'grams': 49.0});
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );

    final g = await lookup.estimatePieceWeight('tortilla', 'piece');
    expect(g, closeTo(49, 0.01));
    expect(llm.callCount, 1);
    expect((await cache.find('tortilla'))!.gramsPerPiece, closeTo(49, 0.01));
  });

  test('estimatePieceWeight rejects implausible weights', () async {
    final cache = FakeFoodCacheRepository();
    final llm = FakeLLMProvider({'grams': 999999.0});
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );
    expect(await lookup.estimatePieceWeight('boulder', 'piece'), isNull);
  });

  test('estimateUnitWeight asks the LLM, caches, and does NOT persist',
      () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(const FoodMacros(
      name: 'rice',
      perHundred: PerHundred(kcal: 130, protein: 2.7, carb: 28, fat: 0.3),
      source: MacroSource.usda,
      isEstimate: false,
    ));
    final llm = FakeLLMProvider({'grams': 158.0});
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );

    final g = await lookup.estimateUnitWeight('rice', 'cup');
    expect(g, closeTo(158, 0.01));
    expect(llm.callCount, 1);
    // Second call for the same food+unit is served from the session cache.
    final g2 = await lookup.estimateUnitWeight('rice', 'cup');
    expect(g2, closeTo(158, 0.01));
    expect(llm.callCount, 1);
    // Crucially, the persisted gramsPerPiece is left untouched (recipe flow owns it).
    expect((await cache.find('rice'))!.gramsPerPiece, isNull);
  });

  test('estimateUnitWeight rejects implausible weights', () async {
    final cache = FakeFoodCacheRepository();
    final llm = FakeLLMProvider({'grams': 0.0});
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(null),
      llm: llm,
    );
    expect(await lookup.estimateUnitWeight('air', 'cup'), isNull);
  });

  test('implausible cached row is ignored and re-resolved', () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(const FoodMacros(
      name: 'black pepper',
      perHundred: PerHundred(kcal: 0, protein: 0, carb: 167, fat: 0),
      source: MacroSource.off,
      isEstimate: false,
    ));
    const goodUsda = PerHundred(kcal: 251, protein: 10, carb: 64, fat: 3.3);
    final lookup = FoodLookup(
      cache: cache,
      off: FakeOpenFoodFactsClient(null),
      usda: FakeUsdaClient(goodUsda),
      llm: FakeLLMProvider({}),
      usdaKey: 'real-key',
    );

    final r = await lookup.resolve('black pepper');
    expect(r!.source, MacroSource.usda);
    expect(r.perHundred.carb, closeTo(64, 0.01));
  });
}

class _ThrowingFoodLookup extends FoodLookup {
  _ThrowingFoodLookup({required super.cache})
      : super(
          off: _ThrowingOFF(),
          usda: _ThrowingUSDA(),
          llm: _ThrowingLLM(),
        );
}

class _ThrowingOFF extends OpenFoodFactsClient {
  _ThrowingOFF() : super();
  @override
  Future<PerHundred?> search(String query) => throw Exception('network error');
}

class _ThrowingUSDA extends UsdaClient {
  _ThrowingUSDA() : super(apiKey: 'fake');
  @override
  Future<PerHundred?> search(String query) => throw Exception('network error');
}

class _ThrowingLLM implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) =>
      throw Exception('llm error');
  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) =>
      throw Exception('llm error');
}
