import '../models/food_unit_weight.dart';
import '../models/macros.dart';
import '../providers/llm/llm_provider.dart';
import 'food_web_grounder.dart';

/// Grounds an unresolved food through an LLM provider's *native* web-search
/// capability. It deliberately has no fallback to normal chat: lack of a
/// supported search tool must allow FoodLookup to continue to its ungrounded
/// estimate path instead of presenting made-up citations.
class LlmFoodWebGrounder extends FoodWebGrounder {
  final LLMProvider llm;
  final DateTime Function() clock;

  LlmFoodWebGrounder({required this.llm, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  @override
  Future<GroundedFoodResult?> ground(String foodName) async {
    return _ground(foodName);
  }

  @override
  Future<GroundedFoodResult?> groundForPortion(
    String foodName, {
    required String requestedUnit,
  }) => _ground(foodName, requestedUnit: requestedUnit);

  @override
  Future<GroundedUnitWeightResult?> groundUnitWeight(
    String foodName, {
    required String requestedUnit,
  }) async {
    final name = foodName.trim();
    final unit = requestedUnit.trim();
    if (name.isEmpty || unit.isEmpty || !llm.supportsWebGrounding) return null;

    try {
      final response = await llm.groundedStructured(
        _unitWeightPrompt(name, unit),
        _unitWeightSchema,
      );
      final citation = _citation(response);
      if (citation == null) return null;

      final data = response.data;
      final matchedName = data['matchedName'];
      final returnedUnit = data['unit'];
      final grams = _number(data['gramsPerUnit']);
      final kind = _unitWeightKind(data['evidenceKind']);
      if (matchedName is! String ||
          matchedName.trim().isEmpty ||
          returnedUnit is! String ||
          returnedUnit.trim().toLowerCase() != unit.toLowerCase() ||
          grams == null ||
          kind == null ||
          !_matchesFood(name, matchedName, kind)) {
        return null;
      }

      return GroundedUnitWeightResult.tryCreate(
        FoodUnitWeight(
          foodName: matchedName.trim(),
          unit: returnedUnit.trim(),
          gramsPerUnit: grams,
          kind: kind,
          provenance: FoodProvenance(
            url: citation.url,
            title: citation.title,
            retrievedAt: clock(),
          ),
        ),
      );
    } catch (_) {
      // Provider timeouts, malformed tool output, and network failures are
      // ordinary unavailable outcomes; the caller may use its usual fallback.
      return null;
    }
  }

  Future<GroundedFoodResult?> _ground(
    String foodName, {
    String? requestedUnit,
  }) async {
    final name = foodName.trim();
    if (name.isEmpty || !llm.supportsWebGrounding) return null;

    final response = await llm.groundedStructured(
      _prompt(name, requestedUnit: requestedUnit),
      _schema,
    );
    final citation = _citation(response);
    if (citation == null) return null;
    final data = response.data;
    final quantity = _number(data['quantity']);
    final unit = data['unit'];
    final kcal = _number(data['kcal']);
    final protein = _number(data['protein']);
    final carb = _number(data['carb']);
    final fat = _number(data['fat']);
    if (quantity == null ||
        unit is! String ||
        kcal == null ||
        protein == null ||
        carb == null ||
        fat == null) {
      return null;
    }

    final inferred = _strings(data['inferredFields']);
    final result = GroundedFoodResult(
      name: data['name'] is String && (data['name'] as String).trim().isNotEmpty
          ? (data['name'] as String).trim()
          : name,
      basis: NutritionBasis(
        quantity: quantity,
        unit: unit.trim(),
        macros: MacroValues(
          kcal: kcal,
          protein: protein,
          carb: carb,
          fat: fat,
          fibre: _number(data['fibre']),
        ),
      ),
      // The prompt and schema explicitly prohibit guessed gram conversions.
      physicalGrams: _number(data['physicalGrams']),
      fibre: _number(data['fibre']),
      sodium: _number(data['sodium']),
      provenance: FoodProvenance(
        url: citation.url,
        title: citation.title,
        retrievedAt: clock(),
        inferredFields: inferred,
      ),
    );
    return result.isValid ? result : null;
  }

  static double? _number(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static Set<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
      : const {};

  static LlmWebCitation? _citation(LlmGroundedStructuredResponse response) {
    for (final item in response.citations) {
      if ((item.url.scheme == 'https' || item.url.scheme == 'http') &&
          item.url.host.isNotEmpty &&
          item.title.trim().isNotEmpty) {
        return item;
      }
    }
    return null;
  }

  static FoodUnitWeightKind? _unitWeightKind(Object? value) => switch (value) {
    'published' => FoodUnitWeightKind.published,
    'average' => FoodUnitWeightKind.average,
    _ => null,
  };

  /// Published evidence must identify the requested product, not merely a
  /// similar food. Generic averages are deliberately allowed only when the
  /// returned generic food still overlaps the query; a different first token
  /// for a multi-word query is treated as a likely brand mismatch.
  static bool _matchesFood(
    String requestedName,
    String matchedName,
    FoodUnitWeightKind kind,
  ) {
    final requested = _nameTokens(requestedName);
    final matched = _nameTokens(matchedName);
    if (requested.isEmpty || matched.isEmpty) return false;
    if (requested.every(matched.contains) ||
        matched.every(requested.contains)) {
      return true;
    }
    if (kind == FoodUnitWeightKind.published) return false;
    return requested.any(matched.contains) &&
        (requested.length == 1 || matched.contains(requested.first));
  }

  static List<String> _nameTokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList();

  static String _prompt(String foodName, {String? requestedUnit}) =>
      '''
Find cited public nutrition information for this exact food or product: "$foodName".
Prefer the manufacturer, restaurant, official nutrition label, then a reputable retailer. ${requestedUnit == null ? '' : 'The user is logging this as "$requestedUnit". Find a source that explicitly publishes nutrition for that exact unit; do not substitute another count unit.'} Return one best-supported result in the requested JSON schema. Keep the nutrition basis exactly as published (for example, "1 serving" or "240 g"). Do not convert it to 100 g. Set physicalGrams only when the cited source explicitly states a gram weight; a serving, item, piece, slice, stick, or count never implies grams. Use null for unavailable values. Put every nutrition field you infer rather than read from the source in inferredFields. Do not claim a source URL in JSON: citations are captured from the web-search tool.
You must use the available web-search tool before calling the emit tool. After searching, call emit with the final JSON object and no prose.
''';

  static const Map<String, dynamic> _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': [
      'name',
      'quantity',
      'unit',
      'kcal',
      'protein',
      'carb',
      'fat',
      'physicalGrams',
      'fibre',
      'sodium',
      'inferredFields',
    ],
    'properties': {
      'name': {'type': 'string'},
      'quantity': {'type': 'number'},
      'unit': {'type': 'string'},
      'kcal': {'type': 'number'},
      'protein': {'type': 'number'},
      'carb': {'type': 'number'},
      'fat': {'type': 'number'},
      'physicalGrams': {
        'type': ['number', 'null'],
      },
      'fibre': {
        'type': ['number', 'null'],
      },
      'sodium': {
        'type': ['number', 'null'],
      },
      'inferredFields': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  };

  static String _unitWeightPrompt(String foodName, String requestedUnit) =>
      '''
Find a cited physical gram weight for exactly one "$requestedUnit" of "$foodName".
Search exact manufacturer, restaurant, or official nutrition-label data first. Then search USDA or other authoritative references and reputable retailers. Only if exact evidence is unavailable, a cited typical generic average is permitted.
The result must be for the exact requested unit "$requestedUnit". do not substitute another count label (for example slice, item, piece, or serving), and never infer that ml equals g. Return the matched food/product name, grams for one requested unit, and whether that gram value is directly published or an inferred generic average. A different branded product is not exact evidence.
You must use the available web-search tool before calling the emit tool. After searching, call emit with the final JSON object and no prose. Do not place source URLs in JSON: citations are captured from the web-search tool.
''';

  static const Map<String, dynamic> _unitWeightSchema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['matchedName', 'unit', 'gramsPerUnit', 'evidenceKind'],
    'properties': {
      'matchedName': {'type': 'string'},
      'unit': {'type': 'string'},
      'gramsPerUnit': {'type': 'number'},
      'evidenceKind': {
        'type': 'string',
        'enum': ['published', 'average'],
      },
    },
  };
}
