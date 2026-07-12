import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/nutrition/food_row.dart';
import 'package:macrochef/services/nutrition/grounding_prompt.dart';

void main() {
  final rows = [
    FoodRow(
      id: 1,
      name: 'Chicken breast, grilled',
      per: const PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6),
    ),
    FoodRow(
      id: 2,
      name: 'Chicken thigh, cooked',
      per: const PerHundred(kcal: 209, protein: 26, carb: 0, fat: 11),
    ),
  ];

  test('embeds the query and every reference food with its macros', () {
    final p = buildGroundingPrompt('grilled chicken', rows);
    expect(p, contains('grilled chicken'));
    expect(
      p,
      contains(
        '- Chicken breast, grilled: kcal 165.0, protein 31.0 g, '
        'carb 0.0 g, fat 3.6 g (per 100 g)',
      ),
    );
    expect(
      p,
      contains(
        '- Chicken thigh, cooked: kcal 209.0, protein 26.0 g, '
        'carb 0.0 g, fat 11.0 g (per 100 g)',
      ),
    );
  });

  test('gives the complete per-100g JSON output directive', () {
    final p = buildGroundingPrompt('x', rows);
    expect(p, contains('Return JSON'));
    final directive = p.substring(p.indexOf('Return JSON'));

    expect(directive, startsWith('Return JSON'));
    expect(directive, contains('kcal'));
    expect(directive, contains('protein (g)'));
    expect(directive, contains('carb (g)'));
    expect(directive, contains('fat (g)'));
    expect(directive, contains('fibre (g)'));
    expect(directive, contains('sodium (mg)'));
    expect(directive, contains('All values per 100 g'));
  });

  test('includes optional fibre and sodium per row only when present', () {
    final p = buildGroundingPrompt('beans', [
      FoodRow(
        id: 3,
        name: 'Beans, cooked',
        per: const PerHundred(
          kcal: 127,
          protein: 8.7,
          carb: 22.8,
          fat: 0.5,
          fibre: 6.4,
          sodium: 1,
        ),
      ),
      FoodRow(
        id: 4,
        name: 'Beans, unsalted',
        per: const PerHundred(kcal: 120, protein: 8, carb: 21, fat: 0.4),
      ),
    ]);
    final lines = p.split('\n');
    final presentLine = lines.singleWhere(
      (line) => line.startsWith('- Beans, cooked:'),
    );
    final nullLine = lines.singleWhere(
      (line) => line.startsWith('- Beans, unsalted:'),
    );

    expect(presentLine, contains('fibre 6.4 g'));
    expect(presentLine, contains('sodium 1.0 mg'));
    expect(nullLine, isNot(contains('fibre')));
    expect(nullLine, isNot(contains('sodium')));
  });
}
