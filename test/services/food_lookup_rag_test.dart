import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/nutrition/embedder.dart';
import 'package:macrochef/services/nutrition/food_row.dart';
import 'package:macrochef/services/nutrition/local_nutrition_db.dart';
import 'package:macrochef/services/nutrition/nutrition_retriever.dart';

class _Cache implements FoodCacheRepository {
  final Map<String, FoodMacros> values = {};
  @override
  Future<FoodMacros?> find(String name) async => values[name.toLowerCase()];
  @override
  Future<void> put(FoodMacros macros) async =>
      values[macros.name.toLowerCase()] = macros;
  @override
  Future<void> deleteByName(String name) async {}
  @override
  Future<int> clearNonOverrides() async => 0;
  @override
  Future<List<FoodMacros>> listOverrides() async => [];
  @override
  Future<List<FoodMacros>> search(String query, {int limit = 8}) async => [];
  @override
  Future<void> setGramsPerPiece(String name, double grams) async {}
  @override
  Future<void> upsertOverride(FoodMacros macros) async {}
  @override
  AppDatabase get db => throw UnimplementedError();
}

class _Off extends OpenFoodFactsClient {
  _Off(this.result) : super();
  final PerHundred? result;
  int calls = 0;
  @override
  Future<PerHundred?> search(String query) async {
    calls++;
    return result;
  }

  @override
  Future<FoodMacros?> searchFood(String query) async {
    calls++;
    return result == null
        ? null
        : FoodMacros(
            name: query,
            perHundred: result!,
            source: MacroSource.off,
            isEstimate: false,
          );
  }
}

class _Usda extends UsdaClient {
  _Usda(this.result) : super(apiKey: 'fake');
  final PerHundred? result;
  int calls = 0;
  @override
  Future<PerHundred?> search(String query) async {
    calls++;
    return result;
  }
}

class _Llm implements LLMProvider {
  _Llm(this.response);
  final Map<String, dynamic> response;
  int calls = 0;
  String? prompt;
  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    calls++;
    this.prompt = prompt;
    return response;
  }

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
}

class _ThrowingLlm extends _Llm {
  _ThrowingLlm() : super(const {});
  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    calls++;
    throw StateError('LLM unavailable');
  }
}

class _Db implements LocalNutritionDb {
  _Db(this.rows, this.vectors);
  final List<FoodRow> rows;
  final Map<int, Float32List> vectors;
  @override
  String get embedderId => 'fake';
  @override
  int get dim => 2;
  @override
  int get count => rows.length;
  @override
  List<FoodRow> ftsPrefilter(String query, {int limit = 50}) => rows;
  @override
  Float32List vectorFor(int id) => vectors[id]!;
  @override
  Future<void> close() async {}
}

class _Embedder implements Embedder {
  _Embedder(this.vector);
  final Float32List vector;
  @override
  String get id => 'fake';
  @override
  int get dim => 2;
  @override
  Future<Float32List> embed(String text) async => vector;
}

class _ThrowingDb extends _Db {
  _ThrowingDb() : super([], {});
  @override
  List<FoodRow> ftsPrefilter(String query, {int limit = 50}) =>
      throw StateError('corrupt pack');
}

FoodRow _row(int id, String name, PerHundred per) =>
    FoodRow(id: id, name: name, per: per);
Float32List _f(double a, double b) => Float32List.fromList([a, b]);

void main() {
  const dbPer = PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6);
  const ai = {'kcal': 150, 'protein': 20, 'carb': 1, 'fat': 5};

  test('direct pack hit is localDb, exact, cached, and zero network', () async {
    final off = _Off(null);
    final usda = _Usda(null);
    final llm = _Llm(ai);
    final lookup = FoodLookup(
      cache: _Cache(),
      off: off,
      usda: usda,
      llm: llm,
      usdaKey: 'key',
      nutritionRetriever: NutritionRetriever(
        db: _Db([_row(1, 'Chicken breast grilled', dbPer)], {1: _f(1, 0)}),
        embedder: _Embedder(_f(1, 0)),
      ),
    );

    final result = await lookup.resolve('chicken breast');

    expect(result!.source, MacroSource.localDb);
    expect(result.isEstimate, isFalse);
    expect(result.perHundred.kcal, 165);
    expect((off.calls, usda.calls, llm.calls), (0, 0, 0));
  });

  test('pack no-direct-hit continues to USDA before any AI estimate', () async {
    final off = _Off(null);
    const usdaPer = PerHundred(kcal: 145, protein: 27, carb: 0, fat: 3);
    final usda = _Usda(usdaPer);
    final llm = _Llm(ai);
    final lookup = FoodLookup(
      cache: _Cache(),
      off: off,
      usda: usda,
      llm: llm,
      usdaKey: 'key',
      nutritionRetriever: NutritionRetriever(
        db: _Db([_row(1, 'Chicken breast grilled', dbPer)], {1: _f(0, 1)}),
        embedder: _Embedder(_f(1, 0)),
      ),
    );

    final result = await lookup.resolve('unusual chicken dish');

    expect(result!.source, MacroSource.usda);
    expect(result.isEstimate, isFalse);
    expect((off.calls, usda.calls, llm.calls), (0, 1, 0));
  });

  test('empty pack result continues to USDA, OFF, then AI estimate', () async {
    final off = _Off(null);
    final usda = _Usda(null);
    final llm = _Llm(ai);
    final lookup = FoodLookup(
      cache: _Cache(),
      off: off,
      usda: usda,
      llm: llm,
      usdaKey: 'key',
      nutritionRetriever: NutritionRetriever(
        db: _Db([], {}),
        embedder: _Embedder(_f(1, 0)),
      ),
    );

    final result = await lookup.resolve('unknown food');

    expect(result!.source, MacroSource.ai);
    expect(llm.prompt, isNot(contains('reference foods')));
    expect((off.calls, usda.calls, llm.calls), (1, 1, 1));
  });

  test(
    'local no-direct-hit still uses valid structured network providers',
    () async {
      final off = _Off(dbPer);
      final usda = _Usda(dbPer);
      final lookup = FoodLookup(
        cache: _Cache(),
        off: off,
        usda: usda,
        llm: _ThrowingLlm(),
        usdaKey: 'key',
        nutritionRetriever: NutritionRetriever(
          db: _Db([], {}),
          embedder: _Embedder(_f(1, 0)),
        ),
      );

      expect((await lookup.resolve('unknown food'))!.source, MacroSource.usda);
      expect((off.calls, usda.calls), (0, 1));
    },
  );

  test('pack failure fails soft to the existing cloud order', () async {
    const usdaPer = PerHundred(kcal: 120, protein: 20, carb: 0, fat: 4);
    final usda = _Usda(usdaPer);
    final lookup = FoodLookup(
      cache: _Cache(),
      off: _Off(null),
      usda: usda,
      llm: _Llm(ai),
      usdaKey: 'key',
      nutritionRetriever: NutritionRetriever(
        db: _ThrowingDb(),
        embedder: _Embedder(_f(1, 0)),
      ),
    );

    final result = await lookup.resolve('chicken');

    expect(result!.source, MacroSource.usda);
    expect(usda.calls, 1);
  });

  test('null retriever preserves USDA-first cloud behavior', () async {
    const usdaPer = PerHundred(kcal: 120, protein: 20, carb: 0, fat: 4);
    final off = _Off(dbPer);
    final usda = _Usda(usdaPer);
    final llm = _Llm(ai);
    final result = await FoodLookup(
      cache: _Cache(),
      off: off,
      usda: usda,
      llm: llm,
      usdaKey: 'key',
    ).resolve('chicken');

    expect(result!.source, MacroSource.usda);
    expect((off.calls, usda.calls, llm.calls), (0, 1, 0));
  });
}
