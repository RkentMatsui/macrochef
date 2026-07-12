import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/cosine.dart';

void main() {
  Float32List f(List<double> xs) => Float32List.fromList(xs);

  test('identical vectors → 1.0', () {
    expect(cosine(f([1, 0, 0]), f([1, 0, 0])), closeTo(1.0, 1e-6));
  });
  test('orthogonal → 0.0', () {
    expect(cosine(f([1, 0]), f([0, 1])), closeTo(0.0, 1e-6));
  });
  test('length mismatch → 0.0 (guard)', () {
    expect(cosine(f([1, 0]), f([1, 0, 0])), 0.0);
  });
  test('zero vector → 0.0 (no NaN)', () {
    expect(cosine(f([0, 0]), f([1, 1])), 0.0);
  });
}
