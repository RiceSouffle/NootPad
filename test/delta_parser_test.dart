import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nootpad/utils/delta_parser.dart';

String delta(List<Map<String, dynamic>> ops) => jsonEncode(ops);

void main() {
  group('DeltaParser.parseLines', () {
    test('detects a normal two-item checklist', () {
      final json = delta([
        {'insert': 'milk'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'}
        },
        {'insert': 'eggs'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        },
      ]);

      final items = DeltaParser.extractChecklist(json);
      expect(items.length, 2);
      expect(items[0].text, 'milk');
      expect(items[0].checked, isFalse);
      expect(items[1].text, 'eggs');
      expect(items[1].checked, isTrue);
    });

    test(
        'attaches block attributes across a merged multi-newline op '
        '(regression: checklist line before an empty checklist line)', () {
      // Quill merges consecutive block-formatted newlines: here the "a" line
      // and an empty line share one "\n\n" op with {list:unchecked}.
      final json = delta([
        {'insert': 'a'},
        {
          'insert': '\n\n',
          'attributes': {'list': 'unchecked'}
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'}
        },
      ]);

      final items = DeltaParser.extractChecklist(json);
      // Both real items must be recognized as checklist lines; before the fix
      // "a" lost its block attribute and disappeared.
      expect(items.map((i) => i.text).toList(), ['a', 'b']);
      expect(items.every((i) => !i.checked), isTrue);
    });

    test('preserves inline attributes on text with embedded newlines', () {
      final json = delta([
        {
          'insert': 'bold one\nbold two',
          'attributes': {'bold': true}
        },
        {'insert': '\n'},
      ]);

      final lines = DeltaParser.parseLines(json);
      // Two text lines, neither is a checklist/heading (inline bold only).
      expect(lines.where((l) => !l.isEmpty).length, 2);
      expect(lines.first.isChecklist, isFalse);
      expect(lines.first.segments.first.attrs?['bold'], isTrue);
    });

    test('extracts embedded image paths', () {
      final json = delta([
        {'insert': 'photo'},
        {'insert': '\n'},
        {
          'insert': {'image': '/data/note_images/a.jpg'}
        },
        {'insert': '\n'},
      ]);

      expect(DeltaParser.extractImages(json), ['/data/note_images/a.jpg']);
    });

    test('extractPlainText concatenates text and ignores embeds', () {
      final json = delta([
        {'insert': 'hello '},
        {
          'insert': {'image': '/x.png'}
        },
        {'insert': 'world'},
        {'insert': '\n'},
      ]);

      expect(DeltaParser.extractPlainText(json), 'hello world');
    });

    test('returns empty structures for malformed JSON', () {
      expect(DeltaParser.parseLines('not json'), isEmpty);
      expect(DeltaParser.extractImages('{'), isEmpty);
      expect(DeltaParser.extractPlainText(''), '');
    });

    test('cache returns stable results for identical content', () {
      final json = delta([
        {'insert': 'cached'},
        {'insert': '\n'},
      ]);
      final first = DeltaParser.parse(json);
      final second = DeltaParser.parse(json);
      expect(identical(first, second), isTrue,
          reason: 'identical content should hit the cache');
    });
  });
}
