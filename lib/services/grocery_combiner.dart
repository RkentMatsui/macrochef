import '../data/database.dart';

class GroceryDraft {
  final String name;
  final String? detail;
  const GroceryDraft(this.name, this.detail);
}

/// De-duplicates ingredients by case-insensitive trimmed name, preserving the
/// first-seen display name and concatenating quantity+unit strings with " + ".
List<GroceryDraft> combineIngredients(List<RecipeIngredient> items) {
  final order = <String>[];
  final names = <String, String>{};
  final parts = <String, List<String>>{};
  for (final i in items) {
    final key = i.name.trim().toLowerCase();
    if (key.isEmpty) continue;
    if (!parts.containsKey(key)) {
      order.add(key);
      names[key] = i.name.trim();
      parts[key] = [];
    }
    final q = (i.quantity ?? '').trim();
    final u = (i.unit ?? '').trim();
    final piece = [q, u].where((s) => s.isNotEmpty).join(' ');
    if (piece.isNotEmpty) parts[key]!.add(piece);
  }
  return order.map((k) {
    final detail = parts[k]!.isEmpty ? null : parts[k]!.join(' + ');
    return GroceryDraft(names[k]!, detail);
  }).toList();
}
