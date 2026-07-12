import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/workout_intent.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/workout_intent_parser.dart';

class _FallbackLLM implements LLMProvider {
  final Map<String, dynamic> result;
  _FallbackLLM(this.result);
  @override
  Future<String> chat(List<ChatMessage> m, {ChatOpts? opts}) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> structured(String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      result;
  @override
  Future<Map<String, dynamic>> vision(Uint8List b, String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      throw UnimplementedError();
}

class _ThrowingLLM implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> m, {ChatOpts? opts}) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> structured(String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      throw Exception('offline');
  @override
  Future<Map<String, dynamic>> vision(Uint8List b, String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      throw UnimplementedError();
}

void main() {
  final parser = WorkoutIntentParser(llm: _ThrowingLLM());

  group('word-number normalizer', () {
    test('maps single words to digits', () {
      expect(WorkoutIntentParser.normalizeNumbers('six reps'), '6 reps');
      expect(WorkoutIntentParser.normalizeNumbers('eighty kilos'), '80 kilos');
    });
    test('maps tens-plus-ones compounds', () {
      expect(
          WorkoutIntentParser.normalizeNumbers('twenty five reps'), '25 reps');
      expect(WorkoutIntentParser.normalizeNumbers('ninety seconds'),
          '90 seconds');
    });
    test('leaves existing digits untouched', () {
      expect(WorkoutIntentParser.normalizeNumbers('6 reps at 80 kg'),
          '6 reps at 80 kg');
    });
  });

  group('regex layer', () {
    test('navigation', () {
      expect(parser.parseRule('next exercise')!.type,
          WorkoutIntentType.nextExercise);
      expect(parser.parseRule('move to next workout')!.type,
          WorkoutIntentType.nextExercise);
      expect(parser.parseRule('previous exercise')!.type,
          WorkoutIntentType.prevExercise);
      expect(parser.parseRule('repeat')!.type,
          WorkoutIntentType.repeatExercise);
      expect(parser.parseRule("what's next")!.type,
          WorkoutIntentType.currentExercise);
    });

    test('plain next and done are commit', () {
      expect(parser.parseRule('next')!.type, WorkoutIntentType.commitSet);
      expect(parser.parseRule('next set')!.type, WorkoutIntentType.commitSet);
      expect(parser.parseRule('done')!.type, WorkoutIntentType.commitSet);
      expect(parser.parseRule('log it')!.type, WorkoutIntentType.commitSet);
    });

    test('finish vs commit are distinct', () {
      expect(parser.parseRule('finish workout')!.type,
          WorkoutIntentType.finishWorkout);
      expect(parser.parseRule('end workout')!.type,
          WorkoutIntentType.finishWorkout);
    });

    test('metrics combine in one utterance', () {
      final i = parser.parseRule('6 reps at 80 kilos')!;
      expect(i.type, WorkoutIntentType.setMetrics);
      expect(i.reps, 6);
      expect(i.weight, 80);
      expect(i.unit, 'kg');
    });

    test('pounds, duration, distance, rpe', () {
      expect(parser.parseRule('135 pounds')!.unit, 'lb');
      expect(parser.parseRule('I ran 30 minutes')!.durationSec, 1800);
      expect(parser.parseRule('5 km')!.distanceM, 5000);
      expect(parser.parseRule('rpe 8')!.rpe, 8);
    });

    test('word-number metrics via normalizer', () {
      final i = parser.parseRule('six reps at eighty kilos')!;
      expect(i.reps, 6);
      expect(i.weight, 80);
    });

    test('rest with and without a number', () {
      expect(parser.parseRule('rest')!.type, WorkoutIntentType.startRest);
      expect(parser.parseRule('rest')!.seconds, isNull);
      expect(parser.parseRule('rest 90 seconds')!.seconds, 90);
      expect(parser.parseRule('start rest for two minutes')!.seconds, 120);
    });

    test('select / progress / target / last-time / exit', () {
      expect(parser.parseRule('start bench press')!.type,
          WorkoutIntentType.selectExercise);
      expect(parser.parseRule('start bench press')!.exerciseName, 'bench press');
      expect(parser.parseRule('how many sets left')!.type,
          WorkoutIntentType.progressQuery);
      expect(parser.parseRule("what's the target")!.type,
          WorkoutIntentType.targetQuery);
      expect(parser.parseRule('what did I do last time')!.type,
          WorkoutIntentType.lastTime);
      expect(parser.parseRule('quit')!.type, WorkoutIntentType.exit);
    });

    test('unrecognized returns null from the rule layer', () {
      expect(parser.parseRule('tell me a joke'), isNull);
    });

    test('conversational mentions of rest do not start a timer', () {
      // Only a leading rest/timer command counts; mid-sentence "rest" must not.
      expect(parser.parseRule('I need to rest my arm'), isNull);
      expect(parser.parseRule('how long should I rest'), isNull);
      // Leading command forms still work.
      expect(parser.parseRule('rest 60 seconds')!.type,
          WorkoutIntentType.startRest);
      expect(parser.parseRule('start rest')!.type, WorkoutIntentType.startRest);
    });
  });

  group('LLM fallback', () {
    test('uses structured result when rules miss', () async {
      final p = WorkoutIntentParser(llm: _FallbackLLM({'intent': 'nextExercise'}));
      final i = await p.parse('go to the thing after this one');
      expect(i.type, WorkoutIntentType.nextExercise);
    });
    test('returns unknown when the LLM throws (offline)', () async {
      final i = await parser.parse('tell me a joke');
      expect(i.type, WorkoutIntentType.unknown);
    });
  });
}
