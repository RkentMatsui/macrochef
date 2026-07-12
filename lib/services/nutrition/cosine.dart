import 'dart:math';
import 'dart:typed_data';

/// Cosine similarity of two vectors. Returns 0.0 on length mismatch or a zero
/// vector (never NaN) so callers can treat it as "no similarity".
double cosine(Float32List a, Float32List b) {
  if (a.length != b.length) return 0.0;
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  if (na == 0 || nb == 0) return 0.0;
  return dot / (sqrt(na) * sqrt(nb));
}
