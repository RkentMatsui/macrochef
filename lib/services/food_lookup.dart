import 'dart:typed_data';
import '../models/macros.dart';
import '../providers/llm/llm_provider.dart';
import '../data/repositories/food_cache_repository.dart';
import 'food_db/open_food_facts_client.dart';
import 'food_db/usda_client.dart';
import 'nutrition/grounding_prompt.dart';
import 'nutrition/food_row.dart';
import 'nutrition/nutrition_retriever.dart';

class FoodLookup {
  final FoodCacheRepository cache;
  final OpenFoodFactsClient off;
  final UsdaClient usda;
  final LLMProvider llm;
  final String? usdaKey;
  final NutritionRetriever? nutritionRetriever;

  FoodLookup({
    required this.cache,
    required this.off,
    required this.usda,
    required this.llm,
    this.usdaKey,
    this.nutritionRetriever,
  });

  Future<FoodMacros?> resolve(String foodName) async {
    try {
      // (1) Cache first — but ignore implausible cached rows (e.g. legacy junk
      // like "167 g carb per 100 g") so they get re-resolved by a better source.
      final cached = await cache.find(foodName);
      if (cached != null && _plausible(cached.perHundred)) return cached;

      // When local retrieval is enabled it replaces both network food sources.
      // Pack failures alone fail soft to the unchanged cloud lookup path.
      final retriever = nutritionRetriever;
      if (retriever != null) {
        List<NutritionMatch>? matches;
        try {
          matches = await retriever.retrieve(foodName);
        } on Object {
          // Missing/corrupt pack or retriever failure: use the legacy cloud path.
        }
        if (matches != null) {
          final hit = retriever.bestDirectHit(matches);
          if (hit != null) {
            final macros = FoodMacros(
              name: foodName,
              perHundred: hit.per,
              source: MacroSource.localDb,
              isEstimate: false,
            );
            await cache.put(macros);
            return macros;
          }

          final prompt = matches.isEmpty
              ? _estimatePrompt(foodName)
              : buildGroundingPrompt(foodName, [
                  for (final match in matches.take(kGroundingTopK)) match.row,
                ]);
          return await _estimate(foodName, prompt);
        }
      }

      // (2) USDA first — authoritative for generic whole foods (chicken, rice,
      // egg). Open Food Facts is a branded/barcode DB and returns an arbitrary
      // product per generic term, so it is only a secondary source now.
      if (usdaKey != null && usdaKey!.isNotEmpty) {
        final usdaResult = await usda.search(foodName);
        if (usdaResult != null && _plausible(usdaResult)) {
          final macros = FoodMacros(
            name: foodName,
            perHundred: usdaResult,
            source: MacroSource.usda,
            isEstimate: false,
          );
          await cache.put(macros);
          return macros;
        }
      }

      // (3) Open Food Facts (branded/barcode) as a secondary source.
      final offResult = await off.search(foodName);
      if (offResult != null && _plausible(offResult)) {
        final macros = FoodMacros(
          name: foodName,
          perHundred: offResult,
          source: MacroSource.off,
          isEstimate: false,
        );
        await cache.put(macros);
        return macros;
      }

      // (4) Fall back to LLM estimate
      return await _estimate(foodName, _estimatePrompt(foodName));
    } catch (_) {
      return null;
    }
  }

  static const Map<String, dynamic> _estimateSchema = {
    'type': 'object',
    'properties': {
      'kcal': {'type': 'number'},
      'protein': {'type': 'number'},
      'carb': {'type': 'number'},
      'fat': {'type': 'number'},
      'fibre': {'type': 'number'},
      'sodium': {'type': 'number'},
    },
    'required': ['kcal', 'protein', 'carb', 'fat'],
  };

  String _estimatePrompt(String foodName) =>
      'Estimate the nutritional values per 100g for "$foodName". '
      'Return JSON with kcal, protein (g), carb (g), fat (g), and optionally fibre (g) and sodium (mg).';

  Future<FoodMacros> _estimate(String foodName, String prompt) async {
    final result = await llm.structured(prompt, _estimateSchema);
    final macros = FoodMacros(
      name: foodName,
      perHundred: PerHundred(
        kcal: _toDouble(result['kcal']),
        protein: _toDouble(result['protein']),
        carb: _toDouble(result['carb']),
        fat: _toDouble(result['fat']),
        fibre: result.containsKey('fibre') ? _toDouble(result['fibre']) : null,
        sodium: result.containsKey('sodium')
            ? _toDouble(result['sodium'])
            : null,
      ),
      source: MacroSource.ai,
      isEstimate: true,
    );
    await cache.put(macros);
    return macros;
  }

  /// Session cache of AI-estimated grams for one household unit of a food,
  /// keyed by "food|unit". Held in memory (the provider is a session-scoped
  /// singleton) so daily-log unit conversions never clobber the persisted
  /// [FoodMacros.gramsPerPiece], which the recipe-ingredient flow owns.
  final Map<String, double> _unitWeightCache = {};

  /// Estimates (via the LLM) the grams in one [unit] (cup/tbsp/piece/…) of
  /// [foodName] — for household-measure logging in the daily log. Cached for
  /// the session. Returns null on failure or an implausible value. Unlike
  /// [estimatePieceWeight], this does NOT persist to the food cache.
  Future<double?> estimateUnitWeight(String foodName, String unit) async {
    final key = '${foodName.toLowerCase().trim()}|${unit.toLowerCase().trim()}';
    final cached = _unitWeightCache[key];
    if (cached != null) return cached;
    try {
      final schema = {
        'type': 'object',
        'properties': {
          'grams': {'type': 'number'},
        },
        'required': ['grams'],
      };
      final prompt =
          'Estimate the typical weight in grams of one "$unit" of "$foodName" '
          'as eaten or measured in cooking. Reply with JSON: a single number '
          'field "grams" for ONE $unit.';
      final result = await llm.structured(prompt, schema);
      final g = _toDouble(result['grams']);
      if (g <= 0 || g > 5000) return null;
      _unitWeightCache[key] = g;
      return g;
    } catch (_) {
      return null;
    }
  }

  /// Estimates (via the LLM) the typical grams of one [unit] of [foodName] and
  /// remembers it on the cached food so future lookups reuse it. Returns null
  /// on failure or an implausible value.
  Future<double?> estimatePieceWeight(String foodName, String unit) async {
    try {
      final schema = {
        'type': 'object',
        'properties': {
          'grams': {'type': 'number'},
        },
        'required': ['grams'],
      };
      final prompt =
          'Estimate the typical weight in grams of one "$unit" of "$foodName" '
          'as used in cooking. Reply with JSON: a single number field "grams".';
      final result = await llm.structured(prompt, schema);
      final g = _toDouble(result['grams']);
      if (g <= 0 || g > 5000) return null;
      await cache.setGramsPerPiece(foodName, g);
      return g;
    } catch (_) {
      return null;
    }
  }

  /// Identifies food from a JPEG (nutrition label or photo) via LLM vision and
  /// returns per-100g macros, or null on failure / unsupported provider. Result
  /// is cached (source = ai) so later text lookups reuse the values.
  ///
  /// Contract: this NEVER throws. Every failure mode — a provider whose
  /// vision() throws [UnsupportedError] (e.g. Groq/OpenAI here), a network or
  /// parse error, an implausible reading, or a blank name — collapses to null.
  /// Callers therefore can't distinguish "provider can't see images" from
  /// "couldn't read the photo"; the UI shows a single message nudging the user
  /// to retry or switch to Claude/Gemini.
  Future<FoodMacros?> resolveFromImage(Uint8List imageBytes) async {
    try {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'kcal': {'type': 'number'},
          'protein': {'type': 'number'},
          'carb': {'type': 'number'},
          'fat': {'type': 'number'},
          'fibre': {'type': 'number'},
          'sodium': {'type': 'number'},
        },
        'required': ['name', 'kcal', 'protein', 'carb', 'fat'],
      };
      const prompt =
          'Look at this food photo. If it shows a nutrition label, read the per-100g values '
          '(convert per-serving to per-100g using the stated serving size). Otherwise estimate per-100g '
          'macros for the visible food. Return JSON: name (string), kcal, protein (g), carb (g), fat (g), '
          'and optionally fibre (g) and sodium (mg). All macro values must be per 100g.';
      final result = await llm.vision(imageBytes, prompt, schema);
      final name = (result['name'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;
      final per = PerHundred(
        kcal: _toDouble(result['kcal']),
        protein: _toDouble(result['protein']),
        carb: _toDouble(result['carb']),
        fat: _toDouble(result['fat']),
        fibre: result.containsKey('fibre') ? _toDouble(result['fibre']) : null,
        sodium: result.containsKey('sodium')
            ? _toDouble(result['sodium'])
            : null,
      );
      if (!_plausible(per)) return null;
      final macros = FoodMacros(
        name: name,
        perHundred: per,
        source: MacroSource.ai,
        isEstimate: true,
      );
      await cache.put(macros);
      return macros;
    } on UnsupportedError {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Rejects physically-impossible per-100g values. A macro can't exceed 100 g
  /// per 100 g of food, energy can't exceed ~900 kcal/100 g (pure fat), and
  /// nothing can be negative. Catches junk DB rows (e.g. "167 g carb / 100 g").
  bool _plausible(PerHundred p) {
    if (p.kcal < 0 || p.protein < 0 || p.carb < 0 || p.fat < 0) return false;
    if (p.protein > 100 || p.carb > 100 || p.fat > 100) return false;
    if (p.kcal > 920) return false;
    return true;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
