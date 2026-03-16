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

/// Utility for parsing Quill Delta JSON into structured data.
class DeltaParser {
  /// Parse Delta JSON string into structured lines.
  static List<DeltaLine> parseLines(String deltaJson) {
    if (deltaJson.isEmpty) return [];

    try {
      final decoded = jsonDecode(deltaJson);
      if (decoded is! List) return [];
      final lines = <DeltaLine>[];
      var currentSegments = <TextSegment>[];

      for (int i = 0; i < decoded.length; i++) {
        final rawOp = decoded[i];
        if (rawOp is! Map<String, dynamic>) continue;
        final insert = rawOp['insert'];
        final rawAttrs = rawOp['attributes'];
        final attrs = (rawAttrs is Map<String, dynamic>) ? rawAttrs : null;

        if (insert is String) {
          if (insert == '\n') {
            lines.add(DeltaLine(
              segments: List.from(currentSegments),
              blockAttrs: attrs,
              newlineOpIndex: i,
            ));
            currentSegments = [];
          } else if (insert.contains('\n')) {
            final parts = insert.split('\n');
            for (int j = 0; j < parts.length; j++) {
              if (parts[j].isNotEmpty) {
                currentSegments
                    .add(TextSegment(text: parts[j], attrs: attrs));
              }
              if (j < parts.length - 1) {
                lines.add(DeltaLine(
                  segments: List.from(currentSegments),
                  newlineOpIndex: i,
                ));
                currentSegments = [];
              }
            }
          } else {
            currentSegments.add(TextSegment(text: insert, attrs: attrs));
          }
        }
      }

      if (currentSegments.isNotEmpty) {
        lines.add(DeltaLine(
          segments: currentSegments,
          newlineOpIndex: -1,
        ));
      }

      return lines;
    } on FormatException {
      return [];
    } catch (_) {
      return [];
    }
  }

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
