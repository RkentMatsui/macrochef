import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/portion_calculator.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/services/food_web_grounder.dart';

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

  @override
  Future<FoodMacros?> searchFood(String query) async => _result == null
      ? null
      : FoodMacros(
          name: query,
          perHundred: _result,
          source: MacroSource.off,
          isEstimate: false,
        );
}

class ServingOpenFoodFactsClient extends OpenFoodFactsClient {
  ServingOpenFoodFactsClient() : super();

  @override
  Future<FoodMacros?> searchFood(String query) async => const FoodMacros(
    name: 'Nescafe Classic stick',
    perHundred: PerHundred(kcal: 350, protein: 0, carb: 70, fat: 7.5),
    source: MacroSource.off,
    isEstimate: false,
    basis: NutritionBasis(
      quantity: 1,
      unit: 'serving',
      macros: MacroValues(kcal: 70, protein: 0, carb: 14, fat: 1.5),
    ),
  );
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

class FakeFoodWebGrounder implements FoodWebGrounder {
  FakeFoodWebGrounder(this.result, {this.error});

  final GroundedFoodResult? result;
  final Object? error;
  int callCount = 0;
  String? requestedUnit;

  @override
  Future<GroundedFoodResult?> ground(String foodName) async {
    callCount++;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<GroundedFoodResult?> groundForPortion(
    String foodName, {
    required String requestedUnit,
  }) {
    this.requestedUnit = requestedUnit;
    return ground(foodName);
  }
}

class StickOpenFoodFactsClient extends OpenFoodFactsClient {
  StickOpenFoodFactsClient() : super();

  @override
  Future<FoodMacros?> searchFood(String query) async => const FoodMacros(
    name: 'Nescafe Classic stick',
    perHundred: PerHundred(kcal: 350, protein: 0, carb: 70, fat: 7.5),
    source: MacroSource.off,
    isEstimate: false,
    basis: NutritionBasis(
      quantity: 1,
      unit: 'stick',
      macros: MacroValues(kcal: 70, protein: 0, carb: 14, fat: 1.5),
    ),
  );
}

GroundedFoodResult groundedFood({Set<String> inferredFields = const {}}) =>
    GroundedFoodResult(
      name: 'web chicken',
      basis: const NutritionBasis(
        quantity: 240,
        unit: 'g',
        macros: MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
      ),
      physicalGrams: 240,
      fibre: null,
      sodium: null,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/nutrition'),
        title: 'Example nutrition',
        retrievedAt: DateTime(2026, 7, 15),
        inferredFields: inferredFields,
      ),
    );

GroundedFoodResult groundedCountFood(String unit) => GroundedFoodResult(
  name: 'instant coffee',
  basis: NutritionBasis(
    quantity: 1,
    unit: unit,
    macros: const MacroValues(kcal: 70, protein: 0, carb: 14, fat: 1.5),
  ),
  physicalGrams: null,
  fibre: null,
  sodium: null,
  provenance: FoodProvenance(
    url: Uri.parse('https://example.com/label'),
    title: 'Official label',
    retrievedAt: DateTime(2026, 7, 15),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const chickenPerHundred = PerHundred(
    kcal: 165,
    protein: 31,
    carb: 0,
    fat: 3.6,
  );

  test('cache hit short-circuits all other lookups', () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(
      const FoodMacros(
        name: 'chicken',
        perHundred: chickenPerHundred,
        source: MacroSource.manual,
        isEstimate: false,
      ),
    );

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

  test('OFF serving data is retained for count-based logging', () async {
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: ServingOpenFoodFactsClient(),
      usda: FakeUsdaClient(null),
      llm: FakeLLMProvider({}),
    ).resolve('nescafe stick classic');

    expect(result!.basis, isNotNull);
    expect(result.basis!.unit, 'serving');
    expect(result.basis!.macros.kcal, 70);
    expect(result.gramsPerPiece, isNull);
  });

  test('OFF preserves a label-provided stick basis for unsaved food', () async {
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: StickOpenFoodFactsClient(),
      usda: FakeUsdaClient(null),
      llm: FakeLLMProvider({}),
    ).resolveForPortion('nescafe stick classic', requestedUnit: 'stick');

    expect(result!.basis!.unit, 'stick');
  });

  test(
    'per-100-g structured result grounds a requested stick before weight',
    () async {
      const per = PerHundred(kcal: 350, protein: 0, carb: 70, fat: 7.5);
      final grounder = FakeFoodWebGrounder(groundedCountFood('stick'));
      final result = await FoodLookup(
        cache: FakeFoodCacheRepository(),
        off: FakeOpenFoodFactsClient(per),
        usda: FakeUsdaClient(null),
        llm: FakeLLMProvider({}),
        webGrounder: grounder,
      ).resolveForPortion('instant coffee stick', requestedUnit: 'stick');

      expect(grounder.callCount, 1);
      expect(grounder.requestedUnit, 'stick');
      expect(result!.basis!.unit, 'stick');
      expect(result.basis!.macros.kcal, 70);
      expect(result.gramsPerPiece, isNull);
    },
  );

  test(
    'count request with no matching cited basis still requires a weight',
    () async {
      const per = PerHundred(kcal: 200, protein: 5, carb: 30, fat: 5);
      final grounder = FakeFoodWebGrounder(groundedCountFood('serving'));
      final result = await FoodLookup(
        cache: FakeFoodCacheRepository(),
        off: FakeOpenFoodFactsClient(per),
        usda: FakeUsdaClient(null),
        llm: FakeLLMProvider({}),
        webGrounder: grounder,
      ).resolveForPortion('unknown bar', requestedUnit: 'piece');

      expect(grounder.requestedUnit, 'piece');
      expect(result!.basis, isNull);
    },
  );

  test('count request falls back to a gramless AI portion estimate', () async {
    const per = PerHundred(kcal: 250, protein: 20, carb: 10, fat: 15);
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: FakeOpenFoodFactsClient(per),
      usda: FakeUsdaClient(null),
      llm: FakeLLMProvider({'kcal': 320, 'protein': 28, 'carb': 12, 'fat': 18}),
      webGrounder: FakeFoodWebGrounder(null),
    ).resolveForPortion('Jollibee chicken breast', requestedUnit: 'piece');

    expect(result, isNotNull);
    expect(result!.basis!.quantity, 1);
    expect(result.basis!.unit, 'piece');
    expect(result.basis!.macros.kcal, 320);
    expect(result.isEstimate, isTrue);
    final portion =
        PortionCalculator.calculate(food: result, quantity: 1, unit: 'piece')
            as ResolvedPortion;
    expect(portion.physicalGrams, isNull);
    expect(portion.macros.protein, 28);
  });

  test(
    'per-100-g structured result grounds a requested piece without grams',
    () async {
      const per = PerHundred(kcal: 250, protein: 8, carb: 35, fat: 8);
      final grounder = FakeFoodWebGrounder(groundedCountFood('piece'));
      final result = await FoodLookup(
        cache: FakeFoodCacheRepository(),
        off: FakeOpenFoodFactsClient(per),
        usda: FakeUsdaClient(null),
        llm: FakeLLMProvider({}),
        webGrounder: grounder,
      ).resolveForPortion('protein bar', requestedUnit: 'piece');

      expect(grounder.requestedUnit, 'piece');
      expect(result!.basis!.unit, 'piece');
      expect(result.gramsPerPiece, isNull);
    },
  );

  test(
    'all-miss falls back to AI estimate with source=ai and isEstimate=true',
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
    },
  );

  test(
    'web grounding runs after structured sources miss, caches its basis',
    () async {
      final cache = FakeFoodCacheRepository();
      final llm = FakeLLMProvider({});
      final grounder = FakeFoodWebGrounder(groundedFood());
      final lookup = FoodLookup(
        cache: cache,
        off: FakeOpenFoodFactsClient(null),
        usda: FakeUsdaClient(null),
        llm: llm,
        usdaKey: 'key',
        webGrounder: grounder,
      );

      final result = await lookup.resolve('web chicken');

      expect(grounder.callCount, 1);
      expect(llm.callCount, 0);
      expect(result!.source, MacroSource.ai);
      expect(result.isEstimate, isFalse);
      expect(result.basis!.quantity, 240);
      expect(result.provenance!.url.host, 'example.com');
      expect(result.perHundred.kcal, closeTo(212.5, 0.01));
      expect((await cache.find('web chicken'))!.basis!.quantity, 240);
    },
  );

  test(
    'grounder failure falls through to the ungrounded AI estimate',
    () async {
      final llm = FakeLLMProvider({
        'kcal': 165.0,
        'protein': 31.0,
        'carb': 0.0,
        'fat': 3.6,
      });
      final grounder = FakeFoodWebGrounder(
        null,
        error: UnsupportedError('web search unavailable'),
      );
      final result = await FoodLookup(
        cache: FakeFoodCacheRepository(),
        off: FakeOpenFoodFactsClient(null),
        usda: FakeUsdaClient(null),
        llm: llm,
        webGrounder: grounder,
      ).resolve('unknown food');

      expect(result!.isEstimate, isTrue);
      expect(grounder.callCount, 1);
      expect(llm.callCount, 1);
    },
  );

  test('valid USDA and OFF hits prevent web grounding', () async {
    const per = PerHundred(kcal: 120, protein: 23, carb: 0, fat: 2.6);
    final grounder = FakeFoodWebGrounder(groundedFood());
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: FakeOpenFoodFactsClient(per),
      usda: FakeUsdaClient(per),
      llm: FakeLLMProvider({}),
      usdaKey: 'key',
      webGrounder: grounder,
    ).resolve('chicken breast');

    expect(result!.source, MacroSource.usda);
    expect(grounder.callCount, 0);
  });

  test('USDA exception falls through to Open Food Facts', () async {
    const offPer = PerHundred(kcal: 100, protein: 20, carb: 2, fat: 1);
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: FakeOpenFoodFactsClient(offPer),
      usda: _ThrowingUSDA(),
      llm: FakeLLMProvider({}),
      usdaKey: 'key',
    ).resolve('fallback food');

    expect(result, isNotNull);
    expect(result!.source, MacroSource.off);
  });

  test('OFF exception falls through to grounded web search', () async {
    final grounder = FakeFoodWebGrounder(groundedFood());
    final result = await FoodLookup(
      cache: FakeFoodCacheRepository(),
      off: _ThrowingOFF(),
      usda: FakeUsdaClient(null),
      llm: FakeLLMProvider({}),
      webGrounder: grounder,
    ).resolve('fallback food');

    expect(result, isNotNull);
    expect(result!.provenance, isNotNull);
    expect(grounder.callCount, 1);
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

  test(
    'implausible OFF result (>100 g carb/100 g) is rejected, falls to AI',
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
    },
  );

  test(
    'estimatePieceWeight asks the LLM and remembers it on the food',
    () async {
      final cache = FakeFoodCacheRepository();
      await cache.put(
        const FoodMacros(
          name: 'tortilla',
          perHundred: PerHundred(kcal: 310, protein: 8, carb: 50, fat: 8),
          source: MacroSource.usda,
          isEstimate: false,
        ),
      );
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
    },
  );

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

  test('estimateUnitWeight asks the LLM, caches, and does NOT persist', () async {
    final cache = FakeFoodCacheRepository();
    await cache.put(
      const FoodMacros(
        name: 'rice',
        perHundred: PerHundred(kcal: 130, protein: 2.7, carb: 28, fat: 0.3),
        source: MacroSource.usda,
        isEstimate: false,
      ),
    );
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
    await cache.put(
      const FoodMacros(
        name: 'black pepper',
        perHundred: PerHundred(kcal: 0, protein: 0, carb: 167, fat: 0),
        source: MacroSource.off,
        isEstimate: false,
      ),
    );
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
    : super(off: _ThrowingOFF(), usda: _ThrowingUSDA(), llm: _ThrowingLLM());
}

class _ThrowingOFF extends OpenFoodFactsClient {
  _ThrowingOFF() : super();
  @override
  Future<PerHundred?> search(String query) => throw Exception('network error');

  @override
  Future<FoodMacros?> searchFood(String query) =>
      throw Exception('network error');
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
  }) => throw Exception('llm error');
  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw Exception('llm error');
}
