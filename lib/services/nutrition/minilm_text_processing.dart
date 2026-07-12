import 'dart:math';
import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Fixed-shape MiniLM model inputs. Both lists contain signed 64-bit values so
/// they can be passed directly to ONNX Runtime as tensors of shape `[1, length]`.
class MiniLmModelInputs {
  final Int64List inputIds;
  final Int64List attentionMask;

  const MiniLmModelInputs({
    required this.inputIds,
    required this.attentionMask,
  });
}

/// Lowercase, greedy WordPiece tokenizer shared by device inference and the
/// offline nutrition-pack builder.
class MiniLmTokenizer {
  static const _requiredTokens = ['[PAD]', '[UNK]', '[CLS]', '[SEP]'];
  static final _controlCategory = RegExp(r'^\p{C}$', unicode: true);
  static final _markCategory = RegExp(r'^\p{Mn}$', unicode: true);
  static final _punctuationCategory = RegExp(r'^\p{P}$', unicode: true);
  static final _spaceSeparatorCategory = RegExp(r'^\p{Zs}$', unicode: true);

  final Map<String, int> _vocab;
  final int maxLength;
  final int maxInputCharactersPerWord;
  late final int _padId = _vocab['[PAD]']!;
  late final int _unknownId = _vocab['[UNK]']!;
  late final int _clsId = _vocab['[CLS]']!;
  late final int _sepId = _vocab['[SEP]']!;

  MiniLmTokenizer.fromVocab(
    List<String> vocab, {
    this.maxLength = 128,
    this.maxInputCharactersPerWord = 100,
  }) : _vocab = {for (var i = 0; i < vocab.length; i++) vocab[i]: i} {
    if (maxLength < 2) {
      throw ArgumentError.value(maxLength, 'maxLength', 'must be at least 2');
    }
    if (maxInputCharactersPerWord <= 0) {
      throw ArgumentError.value(
        maxInputCharactersPerWord,
        'maxInputCharactersPerWord',
        'must be greater than zero',
      );
    }
    final missing = _requiredTokens.where(
      (token) => !_vocab.containsKey(token),
    );
    if (missing.isNotEmpty) {
      throw FormatException(
        'MiniLM vocabulary is missing required tokens: ${missing.join(', ')}',
      );
    }
  }

  MiniLmModelInputs encode(String text) {
    final tokenIds = <int>[_clsId];
    final contentLimit = maxLength - 2;
    final normalized = _stripAccents(_cleanText(text).toLowerCase());
    for (final token in _basicTokens(normalized)) {
      for (final id in _wordPieceIds(token)) {
        if (tokenIds.length - 1 == contentLimit) break;
        tokenIds.add(id);
      }
      if (tokenIds.length - 1 == contentLimit) break;
    }
    tokenIds.add(_sepId);

    final inputIds = Int64List(maxLength);
    inputIds.fillRange(0, maxLength, _padId);
    inputIds.setRange(0, tokenIds.length, tokenIds);
    final attentionMask = Int64List(maxLength);
    attentionMask.fillRange(0, tokenIds.length, 1);
    return MiniLmModelInputs(inputIds: inputIds, attentionMask: attentionMask);
  }

  Iterable<int> _wordPieceIds(String token) sync* {
    if (token.length > maxInputCharactersPerWord) {
      yield _unknownId;
      return;
    }
    var start = 0;
    final pieces = <int>[];
    while (start < token.length) {
      int? matchedId;
      var matchedEnd = token.length;
      while (matchedEnd > start) {
        var piece = token.substring(start, matchedEnd);
        if (start > 0) piece = '##$piece';
        matchedId = _vocab[piece];
        if (matchedId != null) break;
        matchedEnd--;
      }
      if (matchedId == null) {
        yield _unknownId;
        return;
      }
      pieces.add(matchedId);
      start = matchedEnd;
    }
    yield* pieces;
  }

  static Iterable<String> _basicTokens(String text) sync* {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (_isTokenBoundaryWhitespace(rune) ||
          _isPunctuation(rune) ||
          _isCjk(rune)) {
        if (buffer.isNotEmpty) {
          yield buffer.toString();
          buffer.clear();
        }
        if (_isPunctuation(rune) || _isCjk(rune)) {
          yield String.fromCharCode(rune);
        }
      } else {
        buffer.writeCharCode(rune);
      }
    }
    if (buffer.isNotEmpty) yield buffer.toString();
  }

  static String _cleanText(String text) {
    final result = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0 || rune == 0xfffd || _isControl(rune)) continue;
      result.writeCharCode(_isCleanWhitespace(rune) ? 0x20 : rune);
    }
    return result.toString();
  }

  static String _stripAccents(String text) {
    final result = StringBuffer();
    for (final rune in unorm.nfd(text).runes) {
      if (!_isCombiningMark(rune)) result.writeCharCode(rune);
    }
    return result.toString();
  }

  static bool _isControl(int rune) =>
      !_isCleanWhitespace(rune) &&
      _controlCategory.hasMatch(String.fromCharCode(rune));

  static bool _isCombiningMark(int rune) =>
      _markCategory.hasMatch(String.fromCharCode(rune));

  static bool _isCjk(int rune) =>
      (rune >= 0x3400 && rune <= 0x4dbf) ||
      (rune >= 0x4e00 && rune <= 0x9fff) ||
      (rune >= 0xf900 && rune <= 0xfaff) ||
      (rune >= 0x20000 && rune <= 0x2a6df) ||
      (rune >= 0x2a700 && rune <= 0x2b73f) ||
      (rune >= 0x2b740 && rune <= 0x2b81f) ||
      (rune >= 0x2b820 && rune <= 0x2ceaf) ||
      (rune >= 0x2f800 && rune <= 0x2fa1f);

  static bool _isCleanWhitespace(int rune) =>
      rune == 0x20 ||
      rune == 0x09 ||
      rune == 0x0a ||
      rune == 0x0d ||
      _spaceSeparatorCategory.hasMatch(String.fromCharCode(rune));

  static bool _isTokenBoundaryWhitespace(int rune) =>
      _isCleanWhitespace(rune) || rune == 0x2028 || rune == 0x2029;

  static bool _isPunctuation(int rune) =>
      (rune >= 0x21 && rune <= 0x2f) ||
      (rune >= 0x3a && rune <= 0x40) ||
      (rune >= 0x5b && rune <= 0x60) ||
      (rune >= 0x7b && rune <= 0x7e) ||
      _punctuationCategory.hasMatch(String.fromCharCode(rune));
}

/// Attention-mask mean pooling followed by L2 normalization.
Float32List maskedMeanPoolAndNormalize(
  List<List<num>> tokenEmbeddings,
  List<int> attentionMask, {
  required int expectedDimension,
}) {
  if (expectedDimension <= 0) {
    throw ArgumentError.value(
      expectedDimension,
      'expectedDimension',
      'must be greater than zero',
    );
  }
  if (tokenEmbeddings.length != attentionMask.length) {
    throw FormatException(
      'Hidden-state token count (${tokenEmbeddings.length}) does not match '
      'attention mask length (${attentionMask.length})',
    );
  }
  final pooled = Float32List(expectedDimension);
  var attended = 0;
  for (var token = 0; token < tokenEmbeddings.length; token++) {
    final embedding = tokenEmbeddings[token];
    if (embedding.length != expectedDimension) {
      throw FormatException(
        'Hidden-state dimension ${embedding.length} at token $token does not '
        'match expected dimension $expectedDimension',
      );
    }
    if (attentionMask[token] == 0) continue;
    attended++;
    for (var i = 0; i < expectedDimension; i++) {
      pooled[i] += embedding[i].toDouble();
    }
  }
  if (attended == 0) {
    throw StateError('Cannot pool a sequence with no attended tokens');
  }
  var squaredNorm = 0.0;
  for (var i = 0; i < pooled.length; i++) {
    pooled[i] /= attended;
    squaredNorm += pooled[i] * pooled[i];
  }
  final norm = sqrt(squaredNorm);
  if (!norm.isFinite || norm == 0) {
    throw StateError('MiniLM pooled embedding has zero or non-finite norm');
  }
  for (var i = 0; i < pooled.length; i++) {
    pooled[i] /= norm;
  }
  return pooled;
}
