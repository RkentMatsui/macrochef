import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/ui/training/widgets/muscle_atlas.dart';

void main() {
  test('adductor SVG ids map to adductors', () {
    expect(muscleKeyForId('adductor_longus'), 'adductors');
    expect(muscleKeyForId('adductor_magnus_l'), 'adductors');
    expect(muscleKeyForId('gracilis'), 'adductors');
  });

  test('abductor/glute-medius ids map to abductors', () {
    expect(muscleKeyForId('gluteus_medius'), 'abductors');
    expect(muscleKeyForId('tensor_fasciae_latae'), 'abductors');
  });

  test('tibialis maps to its own key, not calves', () {
    expect(muscleKeyForId('tibialis_anterior'), 'tibialis');
  });

  test('gastrocnemius and soleus still map to calves', () {
    expect(muscleKeyForId('gastrocnemius_l'), 'calves');
    expect(muscleKeyForId('soleus'), 'calves');
  });

  test('gluteus maximus still maps to glutes', () {
    expect(muscleKeyForId('gluteus_maximus'), 'glutes');
  });
}
