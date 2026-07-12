// test/models/recipe_preset_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/recipe_preset.dart';

void main() {
  test('round-trips through JSON with a pinned ingredient', () {
    const p = RecipePreset(
      label: 'Tortilla wrap',
      prompt: 'high protein wrap',
      pinnedIngredient: 'tortilla',
    );
    final back = RecipePreset.fromJson(p.toJson());
    expect(back.label, 'Tortilla wrap');
    expect(back.prompt, 'high protein wrap');
    expect(back.pinnedIngredient, 'tortilla');
  });

  test('omits pinnedIngredient when null and parses it back as null', () {
    const p = RecipePreset(label: 'Quick dinner', prompt: 'quick dinner');
    final json = p.toJson();
    expect(json.containsKey('pinnedIngredient'), isFalse);
    expect(RecipePreset.fromJson(json).pinnedIngredient, isNull);
  });
}
