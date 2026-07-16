import 'dart:developer' as developer;
import 'dart:typed_data';
import '../models/macros.dart';
import '../providers/llm/llm_provider.dart';
import '../data/repositories/food_cache_repository.dart';
import 'food_db/open_food_facts_client.dart';
import 'food_db/usda_client.dart';
import 'nutrition/food_row.dart';
import 'nutrition/nutrition_retriever.dart';
import 'food_web_grounder.dart';
import 'food_units.dart';
import 'portion_calculator.dart';

class FoodLookup {
  final FoodCacheRepository cache;
  final OpenFoodFactsClient off;
  final UsdaClient usda;
  final LLMProvider llm;
  final String? usdaKey;
  final NutritionRetriever? nutritionRetriever;
  final FoodWebGrounder? webGrounder;

  FoodLookup({
    required this.cache,
    required this.off,
    required this.usda,
    required this.llm,
    this.usdaKey,
    this.nutritionRetriever,
    this.webGrounder,
  });

  Future<FoodMacros?> resolve(String foodName) => _resolve(foodName);

  /// Resolves food nutrition for a specific logging unit. For a non-mass unit,
  /// a per-100-g-only structured result is not enough: before the UI asks for
  /// a weight, this retries web grounding for a cited matching label basis.
  /// It never estimates or fabricates a gram weight for a count label.
  Future<FoodMacros?> resolveForPortion(
    String foodName, {
    required String requestedUnit,
  }) => _resolve(foodName, requestedUnit: requestedUnit);

  Future<FoodMacros?> _resolve(String foodName, {String? requestedUnit}) async {
    try {
      // (1) Cache first — but ignore implausible cached rows (e.g. legacy junk
      // like "167 g carb per 100 g") so they get re-resolved by a better source.
      final cached = await cache.find(foodName);
      if (cached != null && _plausible(cached.perHundred)) {
        if (_supportsRequestedUnit(cached, requestedUnit)) {
          return cached;
        }
        return await _resolveRequestedUnitFallback(
              foodName,
              requestedUnit: requestedUnit,
            ) ??
            cached;
      }

      // A direct local-pack result is authoritative. A pack miss (including a
      // weak semantic match) continues through the normal USDA/OFF/web
      // waterfall rather than jumping straight to an ungrounded estimate.
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
            if (_supportsRequestedUnit(macros, requestedUnit)) {
              await cache.put(macros);
              return macros;
            }
            await cache.put(macros);
            return await _resolveRequestedUnitFallback(
                  foodName,
                  requestedUnit: requestedUnit,
                ) ??
                macros;
          }
        }
      }

      // (2) USDA first — authoritative for generic whole foods (chicken, rice,
      // egg). Open Food Facts is a branded/barcode DB and returns an arbitrary
      // product per generic term, so it is only a secondary source now.
      if (usdaKey != null && usdaKey!.isNotEmpty) {
        PerHundred? usdaResult;
        try {
          usdaResult = await usda.search(foodName);
        } on Object {
          // A structured provider failure is a miss, not the end of the
          // waterfall. Continue to OFF, grounded web search, then estimation.
          developer.log(
            'source=usda result=failed fallback=open_food_facts',
            name: 'macrochef.food_lookup',
          );
        }
        if (usdaResult != null && _plausible(usdaResult)) {
          final macros = FoodMacros(
            name: foodName,
            perHundred: usdaResult,
            source: MacroSource.usda,
            isEstimate: false,
          );
          if (_supportsRequestedUnit(macros, requestedUnit)) {
            await cache.put(macros);
            return macros;
          }
          await cache.put(macros);
          return await _resolveRequestedUnitFallback(
                foodName,
                requestedUnit: requestedUnit,
              ) ??
              macros;
        }
      }

      // (3) Open Food Facts (branded/barcode) as a secondary source.
      FoodMacros? offResult;
      try {
        offResult = await off.searchFood(foodName);
      } on Object {
        // Fail soft to grounded search and the ordinary AI approximation.
        developer.log(
          'source=open_food_facts result=failed fallback=web_grounding',
          name: 'macrochef.food_lookup',
        );
      }
      if (offResult != null && _plausible(offResult.perHundred)) {
        final macros = FoodMacros(
          name: offResult.name,
          perHundred: offResult.perHundred,
          source: MacroSource.off,
          isEstimate: false,
          gramsPerPiece: offResult.gramsPerPiece,
          basis: offResult.basis,
        );
        if (_supportsRequestedUnit(macros, requestedUnit)) {
          await cache.put(macros);
          return macros;
        }
        await cache.put(macros);
        return await _resolveRequestedUnitFallback(
              foodName,
              requestedUnit: requestedUnit,
            ) ??
            macros;
      }

      // (4) Ground the estimate with a provider-native web search when it is
      // available. This is deliberately after every structured food source and
      // deliberately before the ordinary ungrounded estimate.
      final grounded = await _ground(foodName, requestedUnit: requestedUnit);
      if (grounded != null) return grounded;

      final portionEstimate = await _estimateRequestedPortion(
        foodName,
        requestedUnit,
      );
      if (portionEstimate != null) return portionEstimate;

      // (5) Final fallback: ungrounded LLM estimate.
      developer.log(
        'source=web_grounding result=unavailable fallback=ai_estimate',
        name: 'macrochef.food_lookup',
      );
      return await _estimate(foodName, _estimatePrompt(foodName));
    } catch (_) {
      return null;
    }
  }

  Future<FoodMacros?> _resolveRequestedUnitFallback(
    String foodName, {
    required String? requestedUnit,
  }) async {
    final grounded = await _ground(foodName, requestedUnit: requestedUnit);
    if (grounded != null) return grounded;
    return _estimateRequestedPortion(foodName, requestedUnit);
  }

  Future<FoodMacros?> _estimateRequestedPortion(
    String foodName,
    String? requestedUnit,
  ) async {
    if (requestedUnit == null) return null;
    final unit = foodUnitByLabel(requestedUnit);
    if (unit == null || unit.family == FoodUnitFamily.mass) return null;
    try {
      final result = await llm.structured(
        'Estimate the absolute nutrition for exactly 1 $requestedUnit of '
        '"$foodName". Return calories and macros for that portion, not per '
        '100 g. Do not invent or return a gram weight.',
        _portionEstimateSchema,
      );
      if (!const ['kcal', 'protein', 'carb', 'fat'].every(result.containsKey)) {
        return null;
      }
      final macros = MacroValues(
        kcal: _toDouble(result['kcal']),
        protein: _toDouble(result['protein']),
        carb: _toDouble(result['carb']),
        fat: _toDouble(result['fat']),
        fibre: result.containsKey('fibre') ? _toDouble(result['fibre']) : null,
      );
      if (!_plausibleAbsolute(macros)) return null;
      final food = FoodMacros(
        name: foodName,
        perHundred: PerHundred.zero,
        source: MacroSource.ai,
        isEstimate: true,
        basis: NutritionBasis(quantity: 1, unit: unit.label, macros: macros),
      );
      await cache.put(food);
      developer.log(
        'source=ai_portion_estimate result=accepted unit=${unit.label}',
        name: 'macrochef.food_lookup',
      );
      return food;
    } on Object {
      developer.log(
        'source=ai_portion_estimate result=failed',
        name: 'macrochef.food_lookup',
      );
      return null;
    }
  }

  Future<FoodMacros?> _ground(String foodName, {String? requestedUnit}) async {
    final grounder = webGrounder;
    if (grounder == null) return null;
    try {
      final grounded = requestedUnit == null
          ? await grounder.ground(foodName)
          : await grounder.groundForPortion(
              foodName,
              requestedUnit: requestedUnit,
            );
      if (grounded == null || !grounded.isValid) return null;
      final macros = FoodMacros(
        name: grounded.name,
        perHundred: grounded.derivedPerHundred,
        source: MacroSource.ai,
        isEstimate: grounded.isEstimate,
        gramsPerPiece: _gramsPerCountUnit(grounded),
        basis: grounded.basis,
        provenance: grounded.provenance,
        basisPhysicalGrams: grounded.physicalGrams,
      );
      // A requested count/volume unit must match the cited basis. Do not turn
      // "one serving" into "one piece" simply because both are counts.
      if (!_supportsRequestedUnit(macros, requestedUnit)) return null;
      await cache.put(macros);
      return macros;
    } on Object {
      // A missing, malformed, unsupported, or failed web tool must never
      // prevent the final non-grounded estimate from being available.
      developer.log(
        'source=web_grounding result=failed fallback=ai_estimate',
        name: 'macrochef.food_lookup',
      );
      return null;
    }
  }

  double? _gramsPerCountUnit(GroundedFoodResult grounded) {
    final physicalGrams = grounded.physicalGrams;
    final unit = foodUnitByLabel(grounded.basis.unit);
    if (physicalGrams == null ||
        unit?.family != FoodUnitFamily.count ||
        grounded.basis.quantity <= 0) {
      return null;
    }
    return physicalGrams / grounded.basis.quantity;
  }

  bool _supportsRequestedUnit(FoodMacros food, String? requestedUnit) {
    if (requestedUnit == null) return true;
    final unit = foodUnitByLabel(requestedUnit);
    if (unit == null || unit.family == FoodUnitFamily.mass) return true;
    return PortionCalculator.calculate(
          food: food,
          quantity: 1,
          unit: requestedUnit,
        )
        is ResolvedPortion;
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

  static const Map<String, dynamic> _portionEstimateSchema = {
    'type': 'object',
    'properties': {
      'kcal': {'type': 'number'},
      'protein': {'type': 'number'},
      'carb': {'type': 'number'},
      'fat': {'type': 'number'},
      'fibre': {'type': 'number'},
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

  bool _plausibleAbsolute(MacroValues values) {
    final fields = [
      values.kcal,
      values.protein,
      values.carb,
      values.fat,
      if (values.fibre != null) values.fibre!,
    ];
    if (fields.any((value) => !value.isFinite || value < 0)) return false;
    if (fields.every((value) => value == 0)) return false;
    return values.kcal <= 5000 &&
        values.protein <= 500 &&
        values.carb <= 500 &&
        values.fat <= 500;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
