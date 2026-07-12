import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/ui/training/widgets/muscle_atlas.dart';

void main() {
  group('muscleKeyForId', () {
    test('maps arm vs leg "biceps" correctly', () {
      expect(muscleKeyForId('biceps_femoris_l'), 'hamstrings');
      expect(muscleKeyForId('biceps_brachii_caput_longum_r'), 'biceps');
    });

    test('maps the tracked muscle groups', () {
      expect(muscleKeyForId('pectoralis_major_l'), 'chest');
      expect(muscleKeyForId('rectus_abdominis_1'), 'core');
      expect(muscleKeyForId('external_oblique_3_l'), 'core');
      expect(muscleKeyForId('latissimus_dorsi_r'), 'back');
      expect(muscleKeyForId('trapezius_upper_l'), 'back');
      expect(muscleKeyForId('posterior_deltoid_l'), 'rear-delts');
      expect(muscleKeyForId('lateral_deltoid_r'), 'shoulders');
      expect(muscleKeyForId('anterior_deltoid_l'), 'shoulders');
      expect(muscleKeyForId('triceps_brachii_caput_longum_l'), 'triceps');
      expect(muscleKeyForId('gluteus_maximus_r'), 'glutes');
      expect(muscleKeyForId('vastus_lateralis_l'), 'quads');
      expect(muscleKeyForId('rectus_femoris_r'), 'quads');
      expect(muscleKeyForId('semimembranosus_1_l'), 'hamstrings');
      expect(muscleKeyForId('gastrocnemius_l'), 'calves');
      expect(muscleKeyForId('tibialis_anterior_r'), 'tibialis');
      expect(muscleKeyForId('adductor_longus_l'), 'adductors');
      expect(muscleKeyForId('gluteus_medius_r'), 'abductors');
    });

    test('maps forearm flexors/extensors to forearms (clickable)', () {
      expect(muscleKeyForId('brachioradialis_l'), 'forearms');
      expect(muscleKeyForId('flexor_carpi_radialis_r'), 'forearms');
      expect(muscleKeyForId('extensor_carpi_ulnaris_l'), 'forearms');
      expect(muscleKeyForId('palmaris_longus_l'), 'forearms');
      expect(muscleKeyForId('extensor_digitorum_r'), 'forearms'); // not _longus
      // The lower-leg long toe-extensors share the anterior shin compartment.
      expect(muscleKeyForId('extensor_digitorum_longus_l'), 'tibialis');
      expect(muscleKeyForId('extensor_hallucis_longus_r'), 'tibialis');
    });

    test('returns null for untracked / structural anatomy', () {
      expect(muscleKeyForId(null), isNull);
      expect(muscleKeyForId('sternocleidomastoid_r'), isNull); // neck
      expect(muscleKeyForId('hand_l'), isNull);
      expect(muscleKeyForId('underlayer'), isNull);
    });
  });

  group('MuscleAtlas.load (parses vendored SVGs)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('front figure parses with a viewBox and tracked muscles', () async {
      final fig = await MuscleAtlas.load(back: false);
      expect(fig.viewBox.width, greaterThan(0));
      expect(fig.viewBox.height, greaterThan(0));
      expect(fig.paths, isNotEmpty);
      final keys = fig.paths.map((p) => p.key).whereType<String>().toSet();
      expect(keys, containsAll(<String>['chest', 'core', 'quads']));
      // every parsed path has a non-trivial bounding box
      expect(fig.paths.every((p) => !p.path.getBounds().isEmpty), isTrue);
    });

    test('back figure parses with posterior muscles', () async {
      final fig = await MuscleAtlas.load(back: true);
      expect(fig.paths, isNotEmpty);
      final keys = fig.paths.map((p) => p.key).whereType<String>().toSet();
      expect(keys, containsAll(<String>['back', 'rear-delts', 'hamstrings']));
    });

    test('a known muscle path hit-tests inside its own bounds', () async {
      final fig = await MuscleAtlas.load(back: false);
      final chest = fig.paths.firstWhere((p) => p.key == 'chest');
      expect(chest.path.contains(chest.path.getBounds().center), isTrue);
    });
  });
}
