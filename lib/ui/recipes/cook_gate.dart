// lib/ui/recipes/cook_gate.dart

/// Cooking needs recipe steps AND the downloaded voice pack.
bool canStartCooking({required bool hasSteps, required bool voiceReady}) =>
    hasSteps && voiceReady;

/// A hint for why cooking is disabled, or null when it is enabled.
String? cookDisabledHint({required bool hasSteps, required bool voiceReady}) {
  if (!hasSteps) return 'Add steps to cook this recipe';
  if (!voiceReady) return 'Download the voice pack in Settings to cook';
  return null;
}
