// test/ui/cook_gate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/ui/recipes/cook_gate.dart';

void main() {
  test('cook enabled only when there are steps AND voice is ready', () {
    expect(canStartCooking(hasSteps: true, voiceReady: true), isTrue);
    expect(canStartCooking(hasSteps: true, voiceReady: false), isFalse);
    expect(canStartCooking(hasSteps: false, voiceReady: true), isFalse);
  });

  test('hint explains the missing piece', () {
    expect(cookDisabledHint(hasSteps: true, voiceReady: false),
        'Download the voice pack in Settings to cook');
    expect(cookDisabledHint(hasSteps: false, voiceReady: true),
        'Add steps to cook this recipe');
    expect(cookDisabledHint(hasSteps: true, voiceReady: true), isNull);
  });
}
