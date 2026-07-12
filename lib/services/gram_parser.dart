/// Pure static gram-parser for recipe ingredient quantities.
///
/// Returns null (skip this ingredient) for any unparseable quantity or any
/// non-gram unit (cup, tbsp, tsp, oz, ml, piece, ...). Never throws.
class GramParser {
  GramParser._();

  /// Leading numeric value of a quantity string, tolerating a trailing unit
  /// that a parser folded into the number ("5g", "1.5 cups", "2 tortillas") or
  /// a bare number ("200"). Null when there is no leading number.
  static double? leadingNumber(String? quantity) {
    if (quantity == null) return null;
    final m = RegExp(r'^\s*([0-9]*\.?[0-9]+)').firstMatch(quantity);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  /// The unit text trailing the leading number in [quantity], lowercased and
  /// trimmed. '' when the quantity is a bare number or carries no leading
  /// number. Used to recover a unit the model fused into the quantity ("5g").
  static String trailingUnit(String? quantity) {
    if (quantity == null) return '';
    final m = RegExp(r'^\s*[0-9]*\.?[0-9]+\s*(.*)$').firstMatch(quantity);
    return (m?.group(1) ?? '').trim().toLowerCase();
  }

  static double? parseGrams(String? quantity, String? unit) {
    final q = leadingNumber(quantity);
    if (q == null) return null;

    var u = (unit ?? '').trim().toLowerCase();
    // The number and unit are sometimes returned fused in the quantity field
    // ("5g", "1 kg"); when the explicit unit is missing, recover it from the
    // quantity's trailing text so the ingredient still resolves.
    if (u.isEmpty) u = trailingUnit(quantity);

    if (u.isEmpty || u == 'g' || u == 'gram' || u == 'grams') return q;
    if (u == 'kg' || u == 'kilogram' || u == 'kilograms') return q * 1000.0;
    if (u == 'oz' || u == 'ounce' || u == 'ounces') return q * 28.3495;

    // Non-gram count/volume unit (cup, tbsp, piece, ...) - cannot convert by a
    // fixed factor; the caller's piece path handles it via gramsPerPiece.
    return null;
  }
}
