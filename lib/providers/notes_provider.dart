import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';

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
  int get pinnedCount => _notes.where((n) => n.isPinned).length;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _dbService.getAllNotes();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  Future<Note> createNote({
    String title = '',
    String content = '',
    String category = 'General',
    String color = 'cream',
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      category: category,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    await _dbService.insertNote(note);
    _notes.insert(0, note);
    _applyFilters();
    notifyListeners();
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
    }
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    _applyFilters();
    notifyListeners();
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

  void _applyFilters() {
    _filteredNotes = _notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || note.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }
}
