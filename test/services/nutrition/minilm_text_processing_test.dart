import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/minilm_text_processing.dart';

void main() {
  group('MiniLmTokenizer', () {
    final vocab = <String>[
      '[PAD]',
      '[UNK]',
      '[CLS]',
      '[SEP]',
      'hello',
      'world',
      'cook',
      '##ing',
      ',',
      '!',
      'cafe',
      '你',
      '好',
      'foobar',
      'foo',
      'bar',
    ];

    test('lowercases, splits punctuation, and applies greedy WordPiece', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 10,
      ).encode('Hello, COOKING world!');

      expect(encoded.inputIds, [2, 4, 8, 6, 7, 5, 9, 3, 0, 0]);
      expect(encoded.attentionMask, [1, 1, 1, 1, 1, 1, 1, 1, 0, 0]);
    });

    test('uses unknown token when a word cannot be fully segmented', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 5,
      ).encode('missing');

      expect(encoded.inputIds, [2, 1, 3, 0, 0]);
      expect(encoded.attentionMask, [1, 1, 1, 0, 0]);
    });

    test('truncates content while preserving CLS and SEP', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 5,
      ).encode('hello world hello world');

      expect(encoded.inputIds, [2, 4, 5, 4, 3]);
      expect(encoded.attentionMask, [1, 1, 1, 1, 1]);
    });

    test('rejects vocabularies missing required special tokens', () {
      expect(
        () => MiniLmTokenizer.fromVocab(['[PAD]', '[UNK]', '[CLS]']),
        throwsA(isA<FormatException>()),
      );
    });

    test('strips accents after Unicode decomposition', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 4,
      ).encode('CAFÉ');

      expect(encoded.inputIds, [2, 10, 3, 0]);
    });

    test('removes controls and normalizes Unicode whitespace', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 5,
      ).encode('hel\u0000lo\u00a0world');

      expect(encoded.inputIds, [2, 4, 5, 3, 0]);
    });

    test('removes non-BERT control separators instead of splitting tokens', () {
      const controls = {
        'vertical tab': '\u000b',
        'form feed': '\u000c',
        'next line': '\u0085',
      };
      final tokenizer = MiniLmTokenizer.fromVocab(vocab, maxLength: 4);

      for (final entry in controls.entries) {
        final encoded = tokenizer.encode('foo${entry.value}bar');
        expect(encoded.inputIds, [2, 13, 3, 0], reason: entry.key);
      }
    });

    test('preserves Zl and Zp through cleaning as token separators', () {
      const separators = {
        'line separator': '\u2028',
        'paragraph separator': '\u2029',
      };
      final tokenizer = MiniLmTokenizer.fromVocab(vocab, maxLength: 5);

      for (final entry in separators.entries) {
        final encoded = tokenizer.encode('foo${entry.value}bar');
        expect(encoded.inputIds, [2, 14, 15, 3, 0], reason: entry.key);
      }
    });

    test('splits CJK characters into independent token boundaries', () {
      final encoded = MiniLmTokenizer.fromVocab(
        vocab,
        maxLength: 5,
      ).encode('你好');

      expect(encoded.inputIds, [2, 11, 12, 3, 0]);
    });
  });

  group('maskedMeanPoolAndNormalize', () {
    test('mean-pools only attended tokens and L2 normalizes', () {
      final result = maskedMeanPoolAndNormalize(
        [
          [3.0, 4.0],
          [0.0, 2.0],
          [100.0, 100.0],
        ],
        [1, 1, 0],
        expectedDimension: 2,
      );

      final norm = sqrt(11.25);
      expect(result[0], closeTo(1.5 / norm, 1e-6));
      expect(result[1], closeTo(3.0 / norm, 1e-6));
    });

    test('rejects malformed hidden state dimensions', () {
      expect(
        () => maskedMeanPoolAndNormalize(
          [
            [1.0, 2.0],
            [3.0],
          ],
          [1, 1],
          expectedDimension: 2,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a mask with no attended tokens', () {
      expect(
        () => maskedMeanPoolAndNormalize(
          [
            [1.0, 2.0],
          ],
          [0],
          expectedDimension: 2,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
