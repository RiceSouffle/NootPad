import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;

  List<Note> get notes => _searchQuery.isEmpty && _selectedCategory == 'All'
      ? _notes
      : _filteredNotes;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  List<String> get categories {
    final cats = _notes.map((n) => n.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  int get totalNotes => _notes.length;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _dbService.getAllNotes();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
    _syncWidgets();
  }

  /// Validate that a decoded JSON value is a well-formed Delta ops array.
  static bool isValidDelta(dynamic json) {
    if (json is! List) return false;
    for (final op in json) {
      if (op is! Map<String, dynamic>) return false;
      if (!op.containsKey('insert')) return false;
    }
    return true;
  }

  /// Extract plain text from a note's content (handles both formats).
  static String getPlainText(Note note) {
    if (!note.isDelta || note.content.isEmpty) {
      return note.content;
    }
    try {
      final json = jsonDecode(note.content);
      if (!isValidDelta(json)) return note.content;
      final doc = Document.fromJson(json as List);
      return doc.toPlainText().trim();
    } on FormatException catch (e) {
      debugPrint('Invalid Delta JSON in getPlainText: $e');
      return note.content;
    } catch (e) {
      debugPrint('Error parsing Delta in getPlainText: $e');
      return note.content;
    }
  }

  Future<Note> createNote({
    String title = '',
    String content = '',
    String contentFormat = 'delta',
    String category = 'General',
    String color = 'cream',
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      contentFormat: contentFormat,
      category: category,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    await _dbService.insertNote(note);
    _notes.insert(0, note);
    _applyFilters();
    notifyListeners();
    _syncWidgets();
    return note;
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _dbService.updateNote(updated);

    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _applyFilters();
      notifyListeners();
      _syncWidgets();
    }
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    _applyFilters();
    notifyListeners();
    _syncWidgets();
  }

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _notes[index];
      final updated = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await _dbService.updateNote(updated);
      _notes[index] = updated;
      _notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      _applyFilters();
      notifyListeners();
      _syncWidgets();
    }
  }

  /// Toggle a checklist item's checked state directly from the home card.
  /// [opIndex] is the index of the \n operation in the Delta JSON array.
  Future<void> toggleChecklistItem(String noteId, int opIndex) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final note = _notes[index];
    if (!note.isDelta || note.content.isEmpty) return;

    try {
      final decoded = jsonDecode(note.content);
      if (!isValidDelta(decoded)) return;

      final ops = List<dynamic>.from(decoded as List);
      if (opIndex < 0 || opIndex >= ops.length) return;

      final rawOp = ops[opIndex];
      if (rawOp is! Map<String, dynamic>) return;

      final op = Map<String, dynamic>.from(rawOp);
      final rawAttrs = op['attributes'];
      if (rawAttrs != null && rawAttrs is! Map<String, dynamic>) return;

      final attrs =
          Map<String, dynamic>.from(rawAttrs as Map<String, dynamic>? ?? {});

      if (attrs['list'] == 'checked') {
        attrs['list'] = 'unchecked';
      } else if (attrs['list'] == 'unchecked') {
        attrs['list'] = 'checked';
      } else {
        return; // Not a checklist item
      }

      op['attributes'] = attrs;
      ops[opIndex] = op;

      final updatedContent = jsonEncode(ops);
      final updated = note.copyWith(
        content: updatedContent,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateNote(updated);
      _notes[index] = updated;
      _applyFilters();
      notifyListeners();
      _syncWidgets();
    } on FormatException catch (e) {
      debugPrint('Invalid JSON in checklist toggle: $e');
    } catch (e) {
      debugPrint('Error toggling checklist item: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Sync current notes to home screen widgets.
  void _syncWidgets() {
    WidgetService.syncRecentNotes(_notes)
        .then((_) => WidgetService.syncAllNotesForPicker(_notes))
        .then((_) => WidgetService.syncAllSingleNoteWidgets(_notes))
        .then((_) => WidgetService.updateAllWidgets())
        .catchError((e) => debugPrint('Widget sync error: $e'));
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    _filteredNotes = _notes.where((note) {
      final matchesSearch = query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          (note.isDelta
                  ? getPlainText(note).toLowerCase()
                  : note.content.toLowerCase())
              .contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || note.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }
}
