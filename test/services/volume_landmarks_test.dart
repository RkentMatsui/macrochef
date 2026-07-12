import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/volume_landmarks.dart';

void main() {
  group('hypertrophyFill', () {
    test('untrained / zero sets is cool (0)', () {
      expect(hypertrophyFill('chest', 0), 0.0);
      expect(hypertrophyFill('back', -3), 0.0);
    });

    test('unknown muscle never reddens', () {
      expect(hypertrophyFill('other', 12), 0.0);
      expect(hypertrophyFill('neck', 99), 0.0);
    });

    test('below MEV warms but stays under coral (<0.5)', () {
      // chest MEV = 8; 4 sets is half of MEV.
      final t = hypertrophyFill('chest', 4);
      expect(t, closeTo(0.25, 1e-9));
      expect(t, lessThan(0.5));
    });

    test('hitting MEV lands exactly on coral (0.5)', () {
      expect(hypertrophyFill('chest', 8), closeTo(0.5, 1e-9)); // MEV
      expect(hypertrophyFill('quads', 8), closeTo(0.5, 1e-9)); // MEV
    });

    test('between MEV and MAV ramps coral → red (0.5..1.0)', () {
      // chest: MEV 8, MAV 20 → midpoint 14 sets ≈ 0.75.
      expect(hypertrophyFill('chest', 14), closeTo(0.75, 1e-9));
    });

    test('reaching MAV is full red (1.0)', () {
      expect(hypertrophyFill('chest', 20), closeTo(1.0, 1e-9)); // MAV
      expect(hypertrophyFill('biceps', 18), closeTo(1.0, 1e-9)); // MAV
    });

    test('above MAV clamps at 1.0 (no over-red)', () {
      expect(hypertrophyFill('chest', 30), 1.0);
      expect(hypertrophyFill('triceps', 100), 1.0);
    });

    test('every muscle key has sane, ordered landmarks', () {
      const keys = [
        'chest', 'back', 'shoulders', 'rear-delts', 'biceps', 'triceps',
        'core', 'quads', 'hamstrings', 'glutes', 'calves', 'forearms',
      ];
      for (final k in keys) {
        final lm = kMuscleVolumeLandmarks[k];
        expect(lm, isNotNull, reason: '$k missing landmark');
        expect(lm!.mv, lessThanOrEqualTo(lm.mev), reason: '$k MV<=MEV');
        expect(lm.mev, lessThan(lm.mav), reason: '$k MEV<MAV');
        expect(lm.mav, lessThanOrEqualTo(lm.mrv), reason: '$k MAV<=MRV');
      }
    });
  });
}
