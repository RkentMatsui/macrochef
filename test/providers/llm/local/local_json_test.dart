import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/llm/local/local_json.dart';

void main() {
  group('extractJsonObject', () {
    test('parses a bare object', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
    });

    test('strips ```json fences', () {
      const s = '```json\n{"a":1,"b":"x"}\n```';
      expect(extractJsonObject(s), {'a': 1, 'b': 'x'});
    });

    test('ignores leading prose and trailing text', () {
      const s = 'Sure, here you go:\n{"ok":true}\nHope that helps!';
      expect(extractJsonObject(s), {'ok': true});
    });

    test('returns the first balanced object when nested braces exist', () {
      const s = '{"outer":{"inner":2}}';
      expect(extractJsonObject(s), {'outer': {'inner': 2}});
    });

    test('returns null when no JSON object present', () {
      expect(extractJsonObject('no json here'), isNull);
    });

    test('returns null on malformed JSON', () {
      expect(extractJsonObject('{"a": }'), isNull);
    });
  });
}
