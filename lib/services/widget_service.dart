import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../utils/delta_parser.dart';

/// Service for syncing note data to Android home screen widgets.
@pragma('vm:entry-point')
class WidgetService {
  static const String _androidWidgetProviderCollection =
      'NoteCollectionWidgetProvider';
  static const String _androidWidgetProviderSingle =
      'SingleNoteWidgetProvider';

  /// Initialize home_widget configuration.
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('com.sef.nootpad');
      HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('Error initializing home widget: $e');
    }
  }

  /// Sync recent notes data for the collection widget.
  /// Call this after any note mutation.
  static Future<void> syncRecentNotes(List<Note> notes) async {
    try {
      // Take top 6 notes (pinned first, then by updatedAt)
      final sorted = List<Note>.from(notes)
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      final topNotes = sorted.take(6).toList();

      final notesJson = topNotes.map((note) {
        final plainText = note.isDelta
            ? DeltaParser.extractPlainText(note.content)
            : note.content;
        final preview =
            plainText.length > 80 ? plainText.substring(0, 80) : plainText;
        final checklist = note.isDelta
            ? DeltaParser.extractChecklist(note.content)
            : <ChecklistItem>[];

        return {
          'id': note.id,
          'title': note.title.isEmpty ? 'Untitled' : note.title,
          'preview': preview,
          'color': note.color,
          'colorHex': _colorNameToHex(note.color),
          'category': note.category,
          'isPinned': note.isPinned,
          'updatedAt': _formatRelativeDate(note.updatedAt),
          'hasChecklist': checklist.isNotEmpty,
          'checklistCount': checklist.length,
          'checklistChecked': checklist.where((c) => c.checked).length,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'recent_notes',
        jsonEncode(notesJson),
      );
      await HomeWidget.saveWidgetData<int>(
        'recent_notes_count',
        topNotes.length,
      );
    } catch (e) {
      debugPrint('Error syncing recent notes to widget: $e');
    }
  }

  /// Sync all notes (full data) for the native widget config picker.
  /// The native WidgetConfigActivity reads this to show the note list.
  static Future<void> syncAllNotesForPicker(List<Note> notes) async {
    try {
      final sorted = List<Note>.from(notes)
        ..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

      final notesJson = sorted.map((note) {
        final checklist = note.isDelta
            ? DeltaParser.extractChecklist(note.content)
            : <ChecklistItem>[];
        final plainText = note.isDelta
            ? DeltaParser.extractPlainText(note.content)
            : note.content;

        return {
          'id': note.id,
          'title': note.title.isEmpty ? 'Untitled' : note.title,
          'color': note.color,
          'colorHex': _colorNameToHex(note.color),
          'category': note.category,
          'checklistItems': checklist.map((c) => c.toJson()).toList(),
          'plainText': plainText,
          'updatedAt': _formatRelativeDate(note.updatedAt),
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'all_notes_picker',
        jsonEncode(notesJson),
      );
    } catch (e) {
      debugPrint('Error syncing notes for picker: $e');
    }
  }

  /// Sync a single note for a specific widget instance.
  static Future<void> syncSingleNote(Note note, int widgetId) async {
    try {
      final checklist = note.isDelta
          ? DeltaParser.extractChecklist(note.content)
          : <ChecklistItem>[];
      final plainText = note.isDelta
          ? DeltaParser.extractPlainText(note.content)
          : note.content;

      final noteJson = {
        'id': note.id,
        'title': note.title.isEmpty ? 'Untitled' : note.title,
        'color': note.color,
        'colorHex': _colorNameToHex(note.color),
        'category': note.category,
        'checklistItems': checklist.map((c) => c.toJson()).toList(),
        'plainText': plainText,
        'updatedAt': _formatRelativeDate(note.updatedAt),
      };

      await HomeWidget.saveWidgetData<String>(
        'single_note_$widgetId',
        jsonEncode(noteJson),
      );
    } catch (e) {
      debugPrint('Error syncing single note to widget: $e');
    }
  }

  /// Sync all installed single-note widgets with fresh note data.
  /// Reads the SharedPreferences to find which widgets exist, then
  /// re-syncs each one with the latest version of its note from the DB.
  static Future<void> syncAllSingleNoteWidgets(List<Note> allNotes) async {
    try {
      final installedWidgets = await HomeWidget.getInstalledWidgets();
      for (final widget in installedWidgets) {
        final className = widget.androidClassName ?? '';
        if (!className.contains('SingleNoteWidgetProvider')) continue;

        final widgetId = widget.androidWidgetId;
        if (widgetId == null) continue;
        // Read current widget data to find which note it's showing
        final existingJson =
            await HomeWidget.getWidgetData<String>('single_note_$widgetId');
        if (existingJson == null) continue;

        try {
          final parsed = jsonDecode(existingJson) as Map<String, dynamic>;
          final noteId = parsed['id'] as String?;
          if (noteId == null) continue;

          // Find the note in the current list
          final note = allNotes.where((n) => n.id == noteId).firstOrNull;
          if (note != null) {
            await syncSingleNote(note, widgetId);
          }
        } catch (_) {
          // Skip malformed widget data
        }
      }
    } catch (e) {
      debugPrint('Error syncing single note widgets: $e');
    }
  }

  /// Trigger refresh of all widgets.
  static Future<void> updateAllWidgets() async {
    try {
      await HomeWidget.updateWidget(
        androidName: _androidWidgetProviderCollection,
      );
      await HomeWidget.updateWidget(
        androidName: _androidWidgetProviderSingle,
      );
    } catch (e) {
      debugPrint('Error updating widgets: $e');
    }
  }

  /// Background callback for widget interactions (e.g. checklist toggle).
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    if (uri.host == 'toggle' && uri.pathSegments.length >= 2) {
      // URI: nootpad://toggle/{noteId}/{opIndex}
      final noteId = uri.pathSegments[0];
      final opIndex = int.tryParse(uri.pathSegments[1]);
      if (opIndex == null) return;

      try {
        // Ensure Flutter binding is ready for sqflite in background isolate
        WidgetsFlutterBinding.ensureInitialized();

        final db = DatabaseService();
        final notes = await db.getAllNotes();
        final note = notes.where((n) => n.id == noteId).firstOrNull;
        if (note == null || !note.isDelta || note.content.isEmpty) return;

        final decoded = jsonDecode(note.content);
        if (decoded is! List) return;

        final ops = List<dynamic>.from(decoded);
        if (opIndex < 0 || opIndex >= ops.length) return;

        final rawOp = ops[opIndex];
        if (rawOp is! Map<String, dynamic>) return;

        final op = Map<String, dynamic>.from(rawOp);
        final rawAttrs = op['attributes'];
        if (rawAttrs == null || rawAttrs is! Map<String, dynamic>) return;

        final attrs = Map<String, dynamic>.from(rawAttrs);
        if (attrs['list'] == 'checked') {
          attrs['list'] = 'unchecked';
        } else if (attrs['list'] == 'unchecked') {
          attrs['list'] = 'checked';
        } else {
          return;
        }

        op['attributes'] = attrs;
        ops[opIndex] = op;

        final updatedNote = note.copyWith(
          content: jsonEncode(ops),
          updatedAt: DateTime.now(),
        );
        await db.updateNote(updatedNote);

        // Re-sync all widgets
        final allNotes = await db.getAllNotes();
        await syncRecentNotes(allNotes);
        await syncAllSingleNoteWidgets(allNotes);
        await updateAllWidgets();
      } catch (e) {
        debugPrint('Error toggling checklist in background: $e');
      }
    }
  }

  static String _colorNameToHex(String colorName) {
    switch (colorName) {
      case 'pink':
        return '#FFD4D4';
      case 'blue':
        return '#D4E8FF';
      case 'yellow':
        return '#FFF4B8';
      case 'green':
        return '#D4F0D4';
      case 'orange':
        return '#FFE4C4';
      case 'purple':
        return '#E8D4F0';
      case 'mint':
        return '#D4F0E8';
      case 'cream':
      default:
        return '#FFFEF2';
    }
  }

  static String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.month}/${date.day}';
  }
}
