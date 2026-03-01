import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

/// A text segment with optional inline formatting attributes.
class _TextSegment {
  final String text;
  final Map<String, dynamic>? attrs;

  const _TextSegment({required this.text, this.attrs});
}

/// A parsed line from a Quill Delta document.
class _DeltaLine {
  final List<_TextSegment> segments;
  final Map<String, dynamic>? blockAttrs;
  final int newlineOpIndex;

  const _DeltaLine({
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

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final noteColor = AppColors.getNoteColor(note.color);
    final darkerBorder = HSLColor.fromColor(noteColor)
        .withLightness(
            (HSLColor.fromColor(noteColor).lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    // Build content preview once (avoids double-parsing Delta)
    final contentPreview = _buildContentPreview(context);
    final imageUrls = _extractImageUrls();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: darkerBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: darkerBorder.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          // Clip inside the border so images get rounded corners
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview at top (Google Keep style)
              if (imageUrls.isNotEmpty) _buildImagePreview(imageUrls),

              // Padded text content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pin indicator & category
                    Row(
                      children: [
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color:
                                  AppColors.warmBrown.withValues(alpha: 0.7),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.category,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: note.title.isEmpty
                            ? AppColors.textLight
                            : AppColors.textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (contentPreview != null) ...[
                      const SizedBox(height: 6),
                      contentPreview,
                    ],

                    const SizedBox(height: 8),

                    // Date
                    Text(
                      _formatDate(note.updatedAt),
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Image preview
  // ---------------------------------------------------------------------------

  /// Extract image URLs/paths from the Delta JSON content.
  List<String> _extractImageUrls() {
    if (!note.isDelta || note.content.isEmpty) return [];
    try {
      final decoded = jsonDecode(note.content);
      if (decoded is! List) return [];
      final images = <String>[];
      for (final op in decoded) {
        if (op is! Map<String, dynamic>) continue;
        final insert = op['insert'];
        if (insert is Map) {
          final image = insert['image'];
          if (image is String && image.isNotEmpty) {
            images.add(image);
          }
        }
      }
      return images;
    } on FormatException {
      return [];
    } catch (e) {
      debugPrint('Error extracting image URLs: $e');
      return [];
    }
  }

  /// Build the image preview shown at the top of the card.
  /// Stacks images vertically like Google Keep.
  Widget _buildImagePreview(List<String> imageUrls) {
    // Show up to 3 images stacked; scale height based on count
    const maxVisible = 3;
    final visible = imageUrls.take(maxVisible).toList();
    final remaining = imageUrls.length - maxVisible;

    // Adjust per-image height: 1→120, 2→85 each, 3+→65 each
    final double imageHeight;
    if (visible.length == 1) {
      imageHeight = 120;
    } else if (visible.length == 2) {
      imageHeight = 85;
    } else {
      imageHeight = 65;
    }

    return Column(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          // Add a tiny gap between stacked images
          if (i > 0)
            Container(
              height: 1.5,
              color: AppColors.getNoteColor(note.color),
            ),
          // Last visible image may have a "+N" badge
          if (i == visible.length - 1 && remaining > 0)
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: _buildImage(visible[i]),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '+$remaining',
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: _buildImage(visible[i]),
            ),
        ],
      ],
    );
  }

  /// Render a single image from a local path or network URL.
  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      // Reject paths with traversal attempts
      if (!ImageService.isSafeLocalPath(imageUrl)) {
        return _buildImagePlaceholder();
      }
      return Image.file(
        File(imageUrl.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (ctx, error, stack) => _buildImagePlaceholder(),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (ctx, error, stack) => _buildImagePlaceholder(),
    );
  }

  /// Placeholder shown when an image fails to load.
  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.divider.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.image_rounded, color: AppColors.textLight, size: 32),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content preview (text, checklists, rich text)
  // ---------------------------------------------------------------------------

  /// Builds the content preview area of the card.
  /// Returns null if there is no content to display.
  Widget? _buildContentPreview(BuildContext context) {
    // Plain text notes — simple text preview
    if (!note.isDelta || note.content.isEmpty) {
      if (note.content.isEmpty) return null;
      return Text(
        note.content,
        style: GoogleFonts.quicksand(
          fontSize: 13,
          color: AppColors.textMedium,
          height: 1.4,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Delta note — parse into structured lines
    final lines = _parseDeltaLines();
    final nonEmptyLines = lines.where((l) => !l.isEmpty).toList();
    if (nonEmptyLines.isEmpty) return null;

    // Build preview widgets (max 6 lines)
    final displayLines = nonEmptyLines.take(6).toList();
    final widgets = <Widget>[];
    int orderedListCounter = 0;

    for (int i = 0; i < displayLines.length; i++) {
      final line = displayLines[i];

      if (line.isOrderedList) {
        orderedListCounter++;
      } else {
        orderedListCounter = 0;
      }

      if (line.isChecklist) {
        widgets.add(_buildChecklistRow(context, line));
      } else {
        widgets.add(_buildRichTextLine(line, orderedListCounter));
      }
    }

    // Show remaining count
    if (nonEmptyLines.length > 6) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '+${nonEmptyLines.length - 6} more',
            style: GoogleFonts.quicksand(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Build an interactive checklist row for the card.
  Widget _buildChecklistRow(BuildContext context, _DeltaLine line) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context
            .read<NotesProvider>()
            .toggleChecklistItem(note.id, line.newlineOpIndex);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              line.isChecked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color:
                  line.isChecked ? AppColors.leafGreen : AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildChecklistText(line),
            ),
          ],
        ),
      ),
    );
  }

  /// Build text for a checklist item with strikethrough when checked.
  Widget _buildChecklistText(_DeltaLine line) {
    final isChecked = line.isChecked;
    final baseColor = isChecked ? AppColors.textLight : AppColors.textMedium;

    if (line.segments.isEmpty) {
      return Text('', style: GoogleFonts.quicksand(fontSize: 12));
    }

    final spans = <InlineSpan>[];
    for (final seg in line.segments) {
      TextStyle segStyle = GoogleFonts.quicksand(
        fontSize: 12,
        color: baseColor,
        decoration:
            isChecked ? TextDecoration.lineThrough : TextDecoration.none,
        decorationColor: isChecked ? AppColors.textLight : null,
        decorationThickness: 2.0,
        height: 1.3,
      );

      if (seg.attrs != null && !isChecked) {
        if (seg.attrs!['bold'] == true) {
          segStyle = segStyle.copyWith(fontWeight: FontWeight.w700);
        }
        if (seg.attrs!['italic'] == true) {
          segStyle = segStyle.copyWith(fontStyle: FontStyle.italic);
        }
      }

      spans.add(TextSpan(text: seg.text, style: segStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build a rich text line (with formatting, bullet/number prefix, heading style).
  Widget _buildRichTextLine(_DeltaLine line, int orderedIndex) {
    // Determine base style based on line type
    TextStyle baseStyle;
    if (line.isHeading) {
      final fontSize = line.headingLevel == 1 ? 15.0 : 14.0;
      baseStyle = GoogleFonts.quicksand(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.3,
      );
    } else {
      baseStyle = GoogleFonts.quicksand(
        fontSize: 13,
        color: AppColors.textMedium,
        height: 1.4,
      );
    }

    final spans = <InlineSpan>[];

    // Add list prefix
    if (line.isBulletList) {
      spans.add(TextSpan(
        text: '\u2022 ',
        style: baseStyle.copyWith(color: AppColors.textLight),
      ));
    } else if (line.isOrderedList && orderedIndex > 0) {
      spans.add(TextSpan(
        text: '$orderedIndex. ',
        style: baseStyle.copyWith(color: AppColors.textLight),
      ));
    }

    // Add formatted text segments
    for (final seg in line.segments) {
      TextStyle segStyle = baseStyle;

      if (seg.attrs != null) {
        FontWeight? weight;
        FontStyle? fontStyle;
        final decorations = <TextDecoration>[];

        if (seg.attrs!['bold'] == true) {
          weight = FontWeight.w700;
        }
        if (seg.attrs!['italic'] == true) {
          fontStyle = FontStyle.italic;
        }
        if (seg.attrs!['underline'] == true) {
          decorations.add(TextDecoration.underline);
        }
        if (seg.attrs!['strike'] == true) {
          decorations.add(TextDecoration.lineThrough);
        }

        segStyle = segStyle.copyWith(
          fontWeight: weight ?? segStyle.fontWeight,
          fontStyle: fontStyle,
          decoration: decorations.isEmpty
              ? null
              : TextDecoration.combine(decorations),
        );
      }

      spans.add(TextSpan(text: seg.text, style: segStyle));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(children: spans),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delta parsing
  // ---------------------------------------------------------------------------

  /// Parse the Delta JSON into structured lines with segments and block attributes.
  List<_DeltaLine> _parseDeltaLines() {
    if (!note.isDelta || note.content.isEmpty) return [];

    try {
      final decoded = jsonDecode(note.content);
      if (decoded is! List) return [];
      final lines = <_DeltaLine>[];
      var currentSegments = <_TextSegment>[];

      for (int i = 0; i < decoded.length; i++) {
        final rawOp = decoded[i];
        if (rawOp is! Map<String, dynamic>) continue;
        final insert = rawOp['insert'];
        final rawAttrs = rawOp['attributes'];
        final attrs = (rawAttrs is Map<String, dynamic>) ? rawAttrs : null;

        if (insert is String) {
          if (insert == '\n') {
            lines.add(_DeltaLine(
              segments: List.from(currentSegments),
              blockAttrs: attrs,
              newlineOpIndex: i,
            ));
            currentSegments = [];
          } else if (insert.contains('\n')) {
            // Multi-character insert with embedded newlines
            final parts = insert.split('\n');
            for (int j = 0; j < parts.length; j++) {
              if (parts[j].isNotEmpty) {
                currentSegments
                    .add(_TextSegment(text: parts[j], attrs: attrs));
              }
              if (j < parts.length - 1) {
                // Inline newline — no block attributes
                lines.add(_DeltaLine(
                  segments: List.from(currentSegments),
                  newlineOpIndex: i,
                ));
                currentSegments = [];
              }
            }
          } else {
            currentSegments.add(_TextSegment(text: insert, attrs: attrs));
          }
        }
        // Embeds (images) are handled separately via _extractImageUrls
      }

      // Add any trailing segments without a newline
      if (currentSegments.isNotEmpty) {
        lines.add(_DeltaLine(
          segments: currentSegments,
          newlineOpIndex: -1,
        ));
      }

      return lines;
    } on FormatException {
      return [];
    } catch (e) {
      debugPrint('Error parsing Delta lines: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}
