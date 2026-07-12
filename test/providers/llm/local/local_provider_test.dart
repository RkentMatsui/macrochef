import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/providers/llm/local/local_engine.dart';
import 'package:macrochef/providers/llm/local_provider.dart';

/// Fake engine: records calls, returns scripted outputs, counts loads.
class FakeEngine implements LocalEngine {
  int loads = 0;
  final List<String> prompts = [];
  List<String> scripted;
  FakeEngine(this.scripted);

  @override
  Future<void> load(String modelPath, {LocalBackend backend = LocalBackend.cpu}) async {
    loads++;
  }

  @override
  Future<String> generate(String prompt, {LocalGenOpts opts = const LocalGenOpts()}) async {
    prompts.add(prompt);
    return scripted.removeAt(0);
  }

  @override
  Future<void> dispose() async {}
}

LocalLlmProvider _provider(FakeEngine e) => LocalLlmProvider(
      model: 'gemma3-1b-it',
      engine: e,
      resolveModelPath: () async => '/fake/model.task',
    );

void main() {
  test('chat returns engine text', () async {
    final p = _provider(FakeEngine(['hello there']));
    final out = await p.chat([ChatMessage('user', 'hi')]);
    expect(out, 'hello there');
  });

  test('lazy init loads the model exactly once across calls', () async {
    final e = FakeEngine(['a', 'b']);
    final p = _provider(e);
    await p.chat([ChatMessage('user', '1')]);
    await p.chat([ChatMessage('user', '2')]);
    expect(e.loads, 1);
  });

  test('concurrent first calls still load only once (single-flight)', () async {
    final e = FakeEngine(['a', 'b']);
    final p = _provider(e);
    await Future.wait([
      p.chat([ChatMessage('user', '1')]),
      p.chat([ChatMessage('user', '2')]),
    ]);
    expect(e.loads, 1);
  });

  test('structured parses clean JSON', () async {
    final e = FakeEngine(['{"kcal": 200}']);
    final p = _provider(e);
    final out = await p.structured('x', {'type': 'object'});
    expect(out, {'kcal': 200});
  });

  test('structured retries once on unparseable output then succeeds', () async {
    final e = FakeEngine(['not json', '{"ok": true}']);
    final p = _provider(e);
    final out = await p.structured('x', {'type': 'object'});
    expect(out, {'ok': true});
    expect(e.prompts.length, 2);
  });

  test('structured throws LlmException after retry still fails', () async {
    final e = FakeEngine(['nope', 'still nope']);
    final p = _provider(e);
    expect(() => p.structured('x', {'type': 'object'}), throwsA(isA<LlmException>()));
  });

  test('vision throws UnsupportedError', () async {
    final p = _provider(FakeEngine([]));
    expect(
      () => p.vision(_emptyBytes(), 'desc', {'type': 'object'}),
      throwsUnsupportedError,
    );
  });
}

Uint8List _emptyBytes() => Uint8List(0);
