import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';

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
        child: Padding(
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
                        color: AppColors.warmBrown.withValues(alpha: 0.7),
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

              if (_hasContent(note)) ...[
                const SizedBox(height: 6),
                Text(
                  _getPreviewText(note),
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
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
      ),
    );
  }

  bool _hasContent(Note note) {
    final text = _getPreviewText(note);
    return text.isNotEmpty;
  }

  String _getPreviewText(Note note) {
    if (note.isDelta) {
      return NotesProvider.getPlainText(note);
    }
    return note.content;
  }

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
