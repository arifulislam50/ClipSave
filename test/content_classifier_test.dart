import 'package:clipsave/core/utils/content_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = <String, ClipCategory>{
    'https://flutter.dev': ClipCategory.link,
    'www.example.com/page': ClipCategory.link,
    'HTTP://EXAMPLE.COM': ClipCategory.link,
    'jane.doe+news@mail.example.org': ClipCategory.email,
    '+880 1712-345678': ClipCategory.phone,
    '(555) 123-4567': ClipCategory.phone,
    '01712345678': ClipCategory.phone,
    '42': ClipCategory.number,
    '3.14159': ClipCategory.number,
    '1,234,567': ClipCategory.number,
    '-12.5': ClipCategory.number,
    '2026-11-15': ClipCategory.text,
    'Hello world': ClipCategory.text,
    'https://a.com\nsecond line': ClipCategory.text,
    '': ClipCategory.text,
  };

  cases.forEach((input, expected) {
    test('"${input.replaceAll('\n', r'\n')}" -> ${expected.name}', () {
      expect(ContentClassifier.classify(input), expected);
    });
  });

  test('fromKey falls back to text', () {
    expect(ClipCategory.fromKey('link'), ClipCategory.link);
    expect(ClipCategory.fromKey('unknown'), ClipCategory.text);
    expect(ClipCategory.fromKey(null), ClipCategory.text);
  });
}
