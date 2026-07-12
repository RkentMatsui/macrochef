/// Returns [n] YYYY-MM-DD strings ending on [today] (inclusive), ascending.
/// [today] must be YYYY-MM-DD. Pure — no clock access.
List<String> lastNDays(String today, int n) {
  final p = today.split('-');
  final end = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  final out = <String>[];
  for (var i = n - 1; i >= 0; i--) {
    final d = end.subtract(Duration(days: i));
    out.add('${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}');
  }
  return out;
}

/// Returns the YYYY-MM-DD string for [n] days before [today].
/// [today] must be YYYY-MM-DD. [n] must be >= 0. Pure — no clock access.
String nDaysAgo(String today, int n) {
  final p = today.split('-');
  final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))
      .subtract(Duration(days: n));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
