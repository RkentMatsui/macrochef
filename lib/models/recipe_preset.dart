// lib/models/recipe_preset.dart

/// A saved recipe-generation prompt the user can re-apply with one tap.
/// [pinnedIngredient], when set, is injected into the AI instructions so the
/// generated recipe always includes it (e.g. "tortilla").
class RecipePreset {
  final String label;
  final String prompt;
  final String? pinnedIngredient;

  const RecipePreset({
    required this.label,
    required this.prompt,
    this.pinnedIngredient,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'prompt': prompt,
        if (pinnedIngredient != null) 'pinnedIngredient': pinnedIngredient,
      };

  factory RecipePreset.fromJson(Map<String, dynamic> j) => RecipePreset(
        label: (j['label'] ?? '').toString(),
        prompt: (j['prompt'] ?? '').toString(),
        pinnedIngredient: j['pinnedIngredient']?.toString(),
      );
}
