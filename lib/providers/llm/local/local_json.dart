import 'dart:convert';

/// Best-effort extraction of a single JSON object from raw model output.
///
/// Handles ```` ```json ```` fences, leading/trailing prose, and nested braces
/// by scanning for the first balanced `{...}` span and parsing it. Returns null
/// if nothing parses as a JSON object.
Map<String, dynamic>? extractJsonObject(String raw) {
  final span = _firstBalancedObject(raw);
  if (span == null) return null;
  try {
    final decoded = jsonDecode(span);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

String? _firstBalancedObject(String raw) {
  final start = raw.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < raw.length; i++) {
    final ch = raw[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) return raw.substring(start, i + 1);
    }
  }
  return null;
}
