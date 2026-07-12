import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/gram_parser.dart';

void main() {
  group('GramParser.parseGrams', () {
    test('null quantity returns null', () => expect(GramParser.parseGrams(null, 'g'), isNull));
    test('non-numeric quantity returns null', () => expect(GramParser.parseGrams('two', 'g'), isNull));
    test('bare number, null unit = grams', () => expect(GramParser.parseGrams('200', null), closeTo(200, 0.001)));
    test('empty unit = grams', () => expect(GramParser.parseGrams('150', ''), closeTo(150, 0.001)));
    test('g = grams', () => expect(GramParser.parseGrams('100', 'g'), closeTo(100, 0.001)));
    test('grams = grams', () => expect(GramParser.parseGrams('50', 'grams'), closeTo(50, 0.001)));
    test('GRAMS uppercase = grams', () => expect(GramParser.parseGrams('75', 'GRAMS'), closeTo(75, 0.001)));
    test('kg x1000', () => expect(GramParser.parseGrams('1', 'kg'), closeTo(1000, 0.001)));
    test('KG decimal x1000', () => expect(GramParser.parseGrams('0.5', 'KG'), closeTo(500, 0.001)));
    test('cup returns null', () => expect(GramParser.parseGrams('2', 'cup'), isNull));
    test('tbsp returns null', () => expect(GramParser.parseGrams('1', 'tbsp'), isNull));
    test('tsp returns null', () => expect(GramParser.parseGrams('3', 'tsp'), isNull));
    test('piece returns null', () => expect(GramParser.parseGrams('1', 'piece'), isNull));
    test('ml returns null', () => expect(GramParser.parseGrams('250', 'ml'), isNull));
    test('oz converts by 28.3495', () => expect(GramParser.parseGrams('1', 'oz'), closeTo(28.3495, 1e-4)));
    test('ounces converts', () => expect(GramParser.parseGrams('4', 'ounces'), closeTo(113.398, 1e-3)));

    // Fused number+unit in the quantity field (LLM sometimes returns "5g").
    test('fused g with matching unit', () => expect(GramParser.parseGrams('5g', 'g'), closeTo(5, 0.001)));
    test('fused g with empty unit recovers grams', () => expect(GramParser.parseGrams('5g', ''), closeTo(5, 0.001)));
    test('fused g with null unit recovers grams', () => expect(GramParser.parseGrams('200g', null), closeTo(200, 0.001)));
    test('fused kg with empty unit recovers kg', () => expect(GramParser.parseGrams('1kg', ''), closeTo(1000, 0.001)));
    test('number with spaced unit', () => expect(GramParser.parseGrams('150 g', null), closeTo(150, 0.001)));
    test('fused non-gram unit still skipped', () => expect(GramParser.parseGrams('2cups', ''), isNull));
    test('leading decimal parses', () => expect(GramParser.parseGrams('0.5', 'kg'), closeTo(500, 0.001)));
  });

  group('GramParser.leadingNumber', () {
    test('bare number', () => expect(GramParser.leadingNumber('2'), closeTo(2, 0.001)));
    test('number with unit suffix', () => expect(GramParser.leadingNumber('2 tortillas'), closeTo(2, 0.001)));
    test('fused number+unit', () => expect(GramParser.leadingNumber('5g'), closeTo(5, 0.001)));
    test('decimal', () => expect(GramParser.leadingNumber('0.5 cup'), closeTo(0.5, 0.001)));
    test('non-numeric returns null', () => expect(GramParser.leadingNumber('to taste'), isNull));
    test('null returns null', () => expect(GramParser.leadingNumber(null), isNull));
  });

  group('GramParser.trailingUnit', () {
    test('fused unit', () => expect(GramParser.trailingUnit('5g'), 'g'));
    test('spaced unit lowercased', () => expect(GramParser.trailingUnit('2 Cups'), 'cups'));
    test('bare number has no unit', () => expect(GramParser.trailingUnit('200'), ''));
    test('null has no unit', () => expect(GramParser.trailingUnit(null), ''));
  });
}
