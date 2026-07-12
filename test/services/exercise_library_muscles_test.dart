import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/exercise_library.dart';

void main() {
  Map<String, String?> bySlugPrimary() => {
        for (final e in kBuiltInExercises) e.slug: e.primaryMuscle,
      };

  test('hip adduction/abduction re-pointed to the new muscles', () {
    final m = bySlugPrimary();
    expect(m['hip-adduction'], 'adductors');
    expect(m['hip-abduction'], 'abductors');
  });

  test('tibialis-raise primary muscle is tibialis', () {
    expect(bySlugPrimary()['tibialis-raise'], 'tibialis');
  });

  test('new adductor/abductor/tibialis exercises exist', () {
    final slugs = kBuiltInExercises.map((e) => e.slug).toSet();
    expect(slugs.contains('copenhagen-plank'), isTrue);
    expect(slugs.contains('cable-hip-adduction'), isTrue);
    expect(slugs.contains('cable-hip-abduction'), isTrue);
    expect(slugs.contains('banded-tibialis-raise'), isTrue);
  });

  test('no duplicate slugs in the catalog', () {
    final slugs = kBuiltInExercises.map((e) => e.slug).toList();
    expect(slugs.toSet().length, slugs.length);
  });
}
