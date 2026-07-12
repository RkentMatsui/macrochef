class Ingredient {
  final String name;
  final String? quantity; // e.g. "200" or "1"
  final String? unit;     // e.g. "g", "cup"
  const Ingredient(this.name, {this.quantity, this.unit});
}

class ParsedRecipe {
  final String title;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final int servings;
  const ParsedRecipe({
    required this.title,
    required this.ingredients,
    required this.steps,
    this.servings = 1,
  });
}
