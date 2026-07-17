import 'dart:collection';
import 'dart:convert';

/// A text segment with optional inline formatting attributes.
class TextSegment {
  final String text;
  final Map<String, dynamic>? attrs;

  const TextSegment({required this.text, this.attrs});
}

/// A parsed line from a Quill Delta document.
class DeltaLine {
  final List<TextSegment> segments;
  final Map<String, dynamic>? blockAttrs;
  final int newlineOpIndex;

  const DeltaLine({
    required this.segments,
    this.blockAttrs,
    required this.newlineOpIndex,
  });

  bool get isChecklist =>
      blockAttrs?['list'] == 'checked' || blockAttrs?['list'] == 'unchecked';
  bool get isChecked => blockAttrs?['list'] == 'checked';
  bool get isHeading => blockAttrs != null && blockAttrs!.containsKey('header');
  int get headingLevel => (blockAttrs?['header'] as int?) ?? 0;
  bool get isBulletList => blockAttrs?['list'] == 'bullet';
  bool get isOrderedList => blockAttrs?['list'] == 'ordered';
  String get plainText => segments.map((s) => s.text).join();
  bool get isEmpty => segments.every((s) => s.text.trim().isEmpty);
}

/// A checklist item extracted from Delta JSON.
class ChecklistItem {
  final String text;
  final bool checked;
  final int opIndex;

  const ChecklistItem({
    required this.text,
    required this.checked,
    required this.opIndex,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'checked': checked,
        'opIndex': opIndex,
      };
}

/// The fully-parsed form of a Delta document: structured lines plus any
/// embedded image paths/URLs, computed in a single pass.
class ParsedDelta {
  final List<DeltaLine> lines;
  final List<String> imageUrls;

  const ParsedDelta({required this.lines, required this.imageUrls});

  static const ParsedDelta empty = ParsedDelta(lines: [], imageUrls: []);
}

/// Utility for parsing Quill Delta JSON into structured data.
///
/// Results are cached by raw JSON string so widgets that rebuild frequently
/// (e.g. note cards during scroll/search) don't re-decode unchanged content.
class DeltaParser {
  DeltaParser._();

  static const int _maxCacheEntries = 96;
  static final LinkedHashMap<String, ParsedDelta> _cache =
      LinkedHashMap<String, ParsedDelta>();

  /// Parse Delta JSON into lines + image list, memoized by content string.
  static ParsedDelta parse(String deltaJson) {
    if (deltaJson.isEmpty) return ParsedDelta.empty;

    final cached = _cache.remove(deltaJson);
    if (cached != null) {
      _cache[deltaJson] = cached; // move to most-recently-used
      return cached;
    }

    final result = _parse(deltaJson);

    _cache[deltaJson] = result;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first); // evict least-recently-used
    }
    return result;
  }

  static ParsedDelta _parse(String deltaJson) {
    try {
      final decoded = jsonDecode(deltaJson);
      if (decoded is! List) return ParsedDelta.empty;

      final lines = <DeltaLine>[];
      final images = <String>[];
      var currentSegments = <TextSegment>[];

      for (int i = 0; i < decoded.length; i++) {
        final rawOp = decoded[i];
        if (rawOp is! Map<String, dynamic>) continue;
        final insert = rawOp['insert'];
        final rawAttrs = rawOp['attributes'];
        final attrs = (rawAttrs is Map<String, dynamic>) ? rawAttrs : null;

        if (insert is Map) {
          final image = insert['image'];
          if (image is String && image.isNotEmpty) {
            images.add(image);
          }
          continue;
        }

        if (insert is! String) continue;

        if (insert == '\n') {
          lines.add(DeltaLine(
            segments: List.from(currentSegments),
            blockAttrs: attrs,
            newlineOpIndex: i,
          ));
          currentSegments = [];
        } else if (insert.contains('\n')) {
          // A run consisting only of newlines carries BLOCK attributes (Quill
          // merges consecutive block-formatted newlines, e.g. "\n\n" with
          // {list:checked}); a run mixing text and newlines carries INLINE
          // attributes that apply to the text segments.
          final isAllNewlines = insert.replaceAll('\n', '').isEmpty;
          if (isAllNewlines) {
            for (int n = 0; n < insert.length; n++) {
              lines.add(DeltaLine(
                segments: List.from(currentSegments),
                blockAttrs: attrs,
                newlineOpIndex: i,
              ));
              currentSegments = [];
            }
          } else {
            final parts = insert.split('\n');
            for (int j = 0; j < parts.length; j++) {
              if (parts[j].isNotEmpty) {
                currentSegments.add(TextSegment(text: parts[j], attrs: attrs));
              }
              if (j < parts.length - 1) {
                lines.add(DeltaLine(
                  segments: List.from(currentSegments),
                  newlineOpIndex: i,
                ));
                currentSegments = [];
              }
            }
          }
        } else {
          currentSegments.add(TextSegment(text: insert, attrs: attrs));
        }
      }

      if (currentSegments.isNotEmpty) {
        lines.add(DeltaLine(
          segments: currentSegments,
          newlineOpIndex: -1,
        ));
      }

      return ParsedDelta(lines: lines, imageUrls: images);
    } on FormatException {
      return ParsedDelta.empty;
    } catch (_) {
      return ParsedDelta.empty;
    }
  }

  /// Parse Delta JSON string into structured lines.
  static List<DeltaLine> parseLines(String deltaJson) => parse(deltaJson).lines;

  /// Extract image paths/URLs embedded in the Delta JSON.
  static List<String> extractImages(String deltaJson) =>
      parse(deltaJson).imageUrls;

  /// Extract checklist items from Delta JSON.
  static List<ChecklistItem> extractChecklist(String deltaJson) {
    final lines = parseLines(deltaJson);
    return lines
        .where((l) => l.isChecklist && !l.isEmpty)
        .map((l) => ChecklistItem(
              text: l.plainText,
              checked: l.isChecked,
              opIndex: l.newlineOpIndex,
            ))
        .toList();
  }

  /// Extract plain text from Delta JSON.
  static String extractPlainText(String deltaJson) {
    if (deltaJson.isEmpty) return '';
    try {
      final decoded = jsonDecode(deltaJson);
      if (decoded is! List) return deltaJson;
      final buffer = StringBuffer();
      for (final op in decoded) {
        if (op is Map<String, dynamic>) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return deltaJson;
    }
  }
}
