// lib/ui/recipes/cook_gate.dart

/// Cooking needs recipe steps, the downloaded voice pack, AND a usable AI
/// provider (the voice cook flow parses commands + answers via the LLM).
bool canStartCooking({
  required bool hasSteps,
  required bool voiceReady,
  required bool aiReady,
}) =>
    hasSteps && voiceReady && aiReady;

/// A hint for why cooking is disabled, or null when it is enabled.
String? cookDisabledHint({
  required bool hasSteps,
  required bool voiceReady,
  required bool aiReady,
}) {
  if (!hasSteps) return 'Add steps to cook this recipe';
  if (!voiceReady) return 'Download the voice pack in Settings to cook';
  if (!aiReady) return 'Set up an AI provider in Settings to cook';
  return null;
}
