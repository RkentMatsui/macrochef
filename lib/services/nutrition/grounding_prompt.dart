import 'food_row.dart';

/// Builds a prompt that anchors the LLM's per-100g estimate for [query] to
/// real reference foods [topK].
///
/// The requested fields match the structured schema used by FoodLookup.
String buildGroundingPrompt(String query, List<FoodRow> topK) {
  final refs = StringBuffer();
  for (final row in topK) {
    final per = row.per;
    refs.writeln(
      '- ${row.name}: kcal ${per.kcal}, protein ${per.protein} g, '
      'carb ${per.carb} g, fat ${per.fat} g'
      '${per.fibre != null ? ', fibre ${per.fibre} g' : ''}'
      '${per.sodium != null ? ', sodium ${per.sodium} mg' : ''} (per 100 g)',
    );
  }

  return '''
Estimate the nutrition per 100 g for "$query".

Use these reference foods (all per 100 g) to ground your estimate - pick the
closest, or interpolate; do not contradict them:
$refs
Return JSON with kcal, protein (g), carb (g), fat (g), and optionally fibre (g)
and sodium (mg). All values per 100 g.''';
}
