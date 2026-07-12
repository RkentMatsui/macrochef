// test/ui/cook_gate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/ui/recipes/cook_gate.dart';

void main() {
  test('cook enabled only with steps AND voice ready AND ai ready', () {
    expect(canStartCooking(hasSteps: true, voiceReady: true, aiReady: true),
        isTrue);
    expect(canStartCooking(hasSteps: true, voiceReady: false, aiReady: true),
        isFalse);
    expect(canStartCooking(hasSteps: false, voiceReady: true, aiReady: true),
        isFalse);
    expect(canStartCooking(hasSteps: true, voiceReady: true, aiReady: false),
        isFalse);
  });

  test('hint explains the missing piece (steps → voice → ai order)', () {
    expect(cookDisabledHint(hasSteps: false, voiceReady: true, aiReady: true),
        'Add steps to cook this recipe');
    expect(cookDisabledHint(hasSteps: true, voiceReady: false, aiReady: true),
        'Download the voice pack in Settings to cook');
    expect(cookDisabledHint(hasSteps: true, voiceReady: true, aiReady: false),
        'Set up an AI provider in Settings to cook');
    expect(cookDisabledHint(hasSteps: true, voiceReady: true, aiReady: true),
        isNull);
  });
}
