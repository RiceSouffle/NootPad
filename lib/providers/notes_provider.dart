import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/widget_service.dart';
import '../utils/delta_parser.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final ImageService _imageService = ImageService();
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;

  Timer? _searchDebounce;
  Timer? _syncDebounce;

  /// Cache of lowercased plain text per note id, so search filtering doesn't
  /// re-decode every Delta note on each keystroke.
  final Map<String, String> _searchTextCache = {};

  List<Note> get notes => _searchQuery.isEmpty && _selectedCategory == 'All'
      ? _notes
      : _filteredNotes;

  /// The complete, unfiltered note list — used by AI Q&A so it truly searches
  /// everything regardless of the active on-screen filter.
  List<Note> get allNotes => _notes;

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
    _searchTextCache.clear();
    _sortNotes();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
    _scheduleWidgetSync();
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
    return DeltaParser.extractPlainText(note.content);
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
    _notes.add(note);
    _sortNotes();
    _applyFilters();
    notifyListeners();
    _scheduleWidgetSync();
    return note;
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _dbService.updateNote(updated);

    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _searchTextCache.remove(updated.id);
      _sortNotes();
      _applyFilters();
      notifyListeners();
      _scheduleWidgetSync();
    }
  }

  Future<void> deleteNote(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    final removed = index != -1 ? _notes[index] : null;

    await _dbService.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    _searchTextCache.remove(id);
    _applyFilters();
    notifyListeners();
    _scheduleWidgetSync();

    // Clean up any image files this note owned so they don't leak forever.
    if (removed != null) {
      _deleteImagesFor(removed);
    }
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
      _sortNotes();
      _applyFilters();
      notifyListeners();
      _scheduleWidgetSync();
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
      _searchTextCache.remove(updated.id);
      // Toggling a checklist item shouldn't reshuffle the board under the
      // user's finger, so keep position (no re-sort) here.
      _applyFilters();
      notifyListeners();
      _scheduleWidgetSync();
    } on FormatException catch (e) {
      debugPrint('Invalid JSON in checklist toggle: $e');
    } catch (e) {
      debugPrint('Error toggling checklist item: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Debounce filtering so rapid typing doesn't refilter on every keystroke.
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _applyFilters();
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _deleteImagesFor(Note note) async {
    if (!note.isDelta || note.content.isEmpty) return;
    try {
      final images = DeltaParser.extractImages(note.content);
      for (final path in images) {
        if (ImageService.isSafeLocalPath(path)) {
          final cleaned = path.replaceFirst('file://', '');
          if (await _imageService.isValidImagePath(cleaned)) {
            await _imageService.deleteImage(cleaned);
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting note images: $e');
    }
  }

  /// Sync current notes to home screen widgets (debounced to avoid a storm of
  /// full re-serializations during rapid edits/checklist taps).
  void _scheduleWidgetSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 700), _syncWidgets);
  }

  void _syncWidgets() {
    WidgetService.syncRecentNotes(_notes)
        .then((_) => WidgetService.syncAllNotesForPicker(_notes))
        .then((_) => WidgetService.syncAllSingleNoteWidgets(_notes))
        .then((_) => WidgetService.updateAllWidgets())
        .catchError((e) => debugPrint('Widget sync error: $e'));
  }

  String _searchTextFor(Note note) {
    return _searchTextCache.putIfAbsent(
      note.id,
      () => (note.isDelta ? getPlainText(note) : note.content).toLowerCase(),
    );
  }

  void _applyFilters() {
    // If the selected category no longer exists (e.g. its last note was
    // deleted or recategorized), fall back to 'All' instead of stranding an
    // empty, misleading filter.
    if (_selectedCategory != 'All' &&
        !_notes.any((n) => n.category == _selectedCategory)) {
      _selectedCategory = 'All';
    }

    final query = _searchQuery.toLowerCase();
    _filteredNotes = _notes.where((note) {
      final matchesSearch = query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          _searchTextFor(note).contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || note.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _syncDebounce?.cancel();
    super.dispose();
  }
}
