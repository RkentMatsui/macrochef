import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/cooking_intent.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/intent_parser.dart';

class _NoLlm implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> m, {ChatOpts? opts}) async => '';
  @override
  Future<Map<String, dynamic>> structured(String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      {'intent': 'unknown'};
  @override
  Future<Map<String, dynamic>> vision(
          Uint8List b, String p, Map<String, dynamic> s, {ChatOpts? opts}) async =>
      {};
}

void main() {
  final parser = IntentParser(llm: _NoLlm());

  test('"I used 1325g of chicken" is adjustIngredient with food+grams', () {
    final i = parser.parseRule('I used 1325g of chicken');
    expect(i, isNotNull);
    expect(i!.type, IntentType.adjustIngredient);
    expect(i.grams, 1325);
    expect(i.food, 'chicken');
  });

  test('"set the chicken to 1325 grams" is adjustIngredient', () {
    final i = parser.parseRule('set the chicken to 1325 grams');
    expect(i, isNotNull);
    expect(i!.type, IntentType.adjustIngredient);
    expect(i.grams, 1325);
    expect(i.food!.toLowerCase(), contains('chicken'));
  });

  test('"log 200g of rice" still logs', () {
    final i = parser.parseRule('log 200g of rice');
    expect(i!.type, IntentType.logIngredient);
    expect(i.grams, 200);
  });
}
