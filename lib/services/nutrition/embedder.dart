import 'dart:math';
import 'dart:typed_data';

/// Produces a fixed-length vector for a text. Non-empty vectors are
/// L2-normalised; empty or whitespace-only input returns a zero vector. The `id`
/// encodes the algorithm + dim so a query embedder can be matched against a
/// pack's stored vectors ([NutritionRetriever] refuses to cosine mismatched
/// vectors).
abstract class Embedder {
  Future<Float32List> embed(String text);
  String get id;
  int get dim;
}

/// Pure-Dart character-trigram hashed TF-IDF-ish embedder. No model, no native
/// deps — the guaranteed fallback and the test double. Trigrams give fuzzy
/// overlap/typo tolerance; hashing into [dim] buckets keeps it fixed-length.
class TfidfEmbedder implements Embedder {
  @override
  final int dim;
  TfidfEmbedder({this.dim = 256}) {
    if (dim <= 0) {
      throw ArgumentError.value(dim, 'dim', 'must be greater than zero');
    }
  }

  @override
  String get id => 'tfidf-$dim';

  @override
  Future<Float32List> embed(String text) async {
    final v = Float32List(dim);
    final s = ' ${text.toLowerCase().trim()} ';
    if (s.length >= 3) {
      for (var i = 0; i + 3 <= s.length; i++) {
        final tri = s.substring(i, i + 3);
        v[_fnv1a32(tri) % dim] += 1.0;
      }
    }
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < dim; i++) {
        v[i] /= norm;
      }
    }
    return v;
  }

  static int _fnv1a32(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
