import 'dart:convert';
import '../../../models/chat.dart';

/// Flatten a chat transcript into a single prompt string for a completion model,
/// ending with an "Assistant:" cue so the model continues in the assistant turn.
String buildChatPrompt(List<ChatMessage> messages) {
  final b = StringBuffer();
  for (final m in messages) {
    final label = switch (m.role) {
      'system' => 'System',
      'assistant' => 'Assistant',
      _ => 'User',
    };
    b.writeln('$label: ${m.content}');
  }
  b.write('Assistant:');
  return b.toString();
}

/// Build a prompt that instructs the model to answer [instruction] as a single
/// JSON object matching [schema], with no prose or code fences.
String buildStructuredPrompt(String instruction, Map<String, dynamic> schema) {
  final pretty = const JsonEncoder.withIndent('  ').convert(schema);
  return '''
$instruction

Respond with a SINGLE JSON object that conforms to this JSON schema.
Output ONLY the JSON object. No prose, no markdown, no code fences.

JSON schema:
$pretty

JSON:''';
}
