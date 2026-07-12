import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/embedder.dart';

void main() {
  final e = TfidfEmbedder(dim: 256);

  test('embed returns a unit-length vector of the configured dim', () async {
    final v = await e.embed('grilled chicken breast');
    expect(v.length, 256);
    final norm = v.fold<double>(0, (s, x) => s + x * x);
    expect(norm, closeTo(1.0, 1e-6)); // L2-normalised
  });

  test('similar strings share more mass than unrelated ones', () async {
    double dot(List<double> a, List<double> b) {
      var s = 0.0;
      for (var i = 0; i < a.length; i++) {
        s += a[i] * b[i];
      }
      return s;
    }
    final chicken = await e.embed('chicken breast');
    final chickenGrilled = await e.embed('grilled chicken breast');
    final rice = await e.embed('white rice');
    expect(dot(chicken, chickenGrilled), greaterThan(dot(chicken, rice)));
  });

  test('id encodes the algorithm + dim so pack vectors can be matched', () {
    expect(e.id, 'tfidf-256');
    expect(e.dim, 256);
  });

  test('uses deterministic FNV-1a trigram buckets', () async {
    final v = await TfidfEmbedder(dim: 8).embed('abc');

    expect(
      v,
      orderedEquals(<double>[
        0.5773502588272095,
        0,
        0,
        0.5773502588272095,
        0,
        0,
        0.5773502588272095,
        0,
      ]),
    );
  });

  test('empty and whitespace-only text returns a zero vector', () async {
    for (final text in ['', ' ', '\t\n']) {
      final v = await e.embed(text);
      expect(v.length, 256);
      expect(v, everyElement(0.0));
    }
  });

  test('rejects non-positive dimensions', () {
    expect(() => TfidfEmbedder(dim: 0), throwsArgumentError);
    expect(() => TfidfEmbedder(dim: -1), throwsArgumentError);
  });
}
