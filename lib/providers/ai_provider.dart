import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/ai_service.dart';
import '../services/ai_prompts.dart';

enum AiStatus { idle, loading, success, error }

enum WritingAction { expand, rewrite, shorten, continueWriting }

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();

  AiStatus _status = AiStatus.idle;
  String _result = '';
  String _errorMessage = '';
  bool _lastTruncated = false;

  AiStatus get status => _status;
  String get result => _result;
  String get errorMessage => _errorMessage;

  /// True when the most recent successful generation was cut off by the
  /// model's token limit (so the UI can warn before a destructive replace).
  bool get lastTruncated => _lastTruncated;

  bool get isAvailable => _aiService.isAvailable;
  AiBackend get activeBackend => _aiService.activeBackend;
  String get modelKey => _aiService.modelKey;

  // Coverage stats for the last Q&A, so the UI can be honest about what was
  // actually searched.
  int _lastNotesSearched = 0;
  int _lastNotesTotal = 0;
  bool _lastContextTruncated = false;
  int get lastNotesSearched => _lastNotesSearched;
  int get lastNotesTotal => _lastNotesTotal;
  bool get lastContextTruncated => _lastContextTruncated;

  Future<void> initialize() async {
    await _aiService.initialize();
    notifyListeners();
  }

  Future<void> setModel(String key) async {
    await _aiService.setModelKey(key);
    notifyListeners();
  }

  void reset() {
    _status = AiStatus.idle;
    _result = '';
    _errorMessage = '';
    _lastTruncated = false;
    notifyListeners();
  }

  // -- Summarize --
  Future<String> summarize(Note note) async {
    _setLoading();
    try {
      final plainText = NotesProvider.getPlainText(note);
      if (plainText.trim().isEmpty) {
        _setError('This Noot has no content to summarize.');
        throw AiApiException('No content');
      }
      final result = await _aiService.generate(
        systemPrompt: AiPrompts.summarizeSystem,
        userPrompt: AiPrompts.summarizeUser(note.title, plainText),
        maxTokens: 400,
      );
      _setSuccess(result.text, truncated: result.truncated);
      return result.text;
    } on AiUnavailableException {
      _setError('Add your API key in Settings to use Noot AI.');
      rethrow;
    } catch (e) {
      if (_status != AiStatus.error) _setError(e.toString());
      rethrow;
    }
  }

  // -- Writing Assistant --
  Future<String> assistWriting({
    required String selectedText,
    required WritingAction action,
  }) async {
    _setLoading();
    try {
      final String userPrompt;
      // Expand/continue can legitimately produce more text than the input, so
      // give them more headroom to avoid mid-sentence truncation.
      final int maxTokens;
      switch (action) {
        case WritingAction.expand:
          userPrompt = AiPrompts.writingExpand(selectedText);
          maxTokens = 1024;
        case WritingAction.rewrite:
          userPrompt = AiPrompts.writingRewrite(selectedText);
          maxTokens = 768;
        case WritingAction.shorten:
          userPrompt = AiPrompts.writingShorten(selectedText);
          maxTokens = 512;
        case WritingAction.continueWriting:
          userPrompt = AiPrompts.writingContinue(selectedText);
          maxTokens = 1024;
      }
      final result = await _aiService.generate(
        systemPrompt: AiPrompts.writingSystem,
        userPrompt: userPrompt,
        maxTokens: maxTokens,
      );
      _setSuccess(result.text, truncated: result.truncated);
      return result.text;
    } on AiUnavailableException {
      _setError('Add your API key in Settings to use Noot AI.');
      rethrow;
    } catch (e) {
      if (_status != AiStatus.error) _setError(e.toString());
      rethrow;
    }
  }

  // -- Smart Categorization --
  Future<String> suggestCategory(Note note) async {
    _setLoading();
    try {
      final plainText = NotesProvider.getPlainText(note);
      final result = await _aiService.generate(
        systemPrompt: AiPrompts.categorizeSystem,
        userPrompt: AiPrompts.categorizeUser(note.title, plainText),
        maxTokens: 20,
      );
      final category = _sanitizeCategory(result.text);
      if (category == null) {
        _setError('Couldn\'t suggest a category.');
        throw AiApiException('Invalid category suggestion');
      }
      _setSuccess(category);
      return category;
    } on AiUnavailableException {
      _setError('Add your API key in Settings to use Noot AI.');
      rethrow;
    } catch (e) {
      if (_status != AiStatus.error) _setError(e.toString());
      rethrow;
    }
  }

  /// Normalize a model category reply to a short, clean label, or null if the
  /// reply doesn't look like a category (prompt-injection / chatty output).
  String? _sanitizeCategory(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    // Take only the first line.
    text = text.split('\n').first.trim();
    // Strip surrounding quotes and trailing punctuation.
    text = text.replaceAll(RegExp(r'''^["'`]+|["'`.!?,;:]+$'''), '').trim();
    if (text.isEmpty || text.length > 30) return null;
    final words = text.split(RegExp(r'\s+'));
    if (words.length > 3) return null;
    return text;
  }

  // -- AI Search / Q&A --
  Future<String> askQuestion({
    required String question,
    required List<Note> notes,
  }) async {
    _setLoading();
    _lastNotesTotal = notes.length;
    _lastNotesSearched = 0;
    _lastContextTruncated = false;
    try {
      const budget = 12000;
      const perNote = 800;
      final buffer = StringBuffer();
      var included = 0;
      for (final note in notes) {
        if (buffer.length >= budget) {
          _lastContextTruncated = true;
          break;
        }
        final plainText = NotesProvider.getPlainText(note);
        buffer.writeln(
            '--- Note: ${note.title.isEmpty ? "Untitled" : note.title} ---');
        buffer.writeln(plainText.length > perNote
            ? '${plainText.substring(0, perNote)}...'
            : plainText);
        buffer.writeln();
        included++;
      }
      _lastNotesSearched = included;

      final result = await _aiService.generate(
        systemPrompt: AiPrompts.qaSystem,
        userPrompt: AiPrompts.qaUser(question, buffer.toString()),
        maxTokens: 1024,
      );
      _setSuccess(result.text, truncated: result.truncated);
      return result.text;
    } on AiUnavailableException {
      _setError('Add your API key in Settings to use Noot AI.');
      rethrow;
    } catch (e) {
      if (_status != AiStatus.error) _setError(e.toString());
      rethrow;
    }
  }

  Future<void> onApiKeyChanged() async {
    await _aiService.onApiKeyChanged();
    notifyListeners();
  }

  /// Abort any in-flight request (called when an AI sheet is dismissed).
  void cancelInFlight() {
    _aiService.cancelInFlight();
  }

  void _setLoading() {
    _status = AiStatus.loading;
    _result = '';
    _errorMessage = '';
    _lastTruncated = false;
    notifyListeners();
  }

  void _setSuccess(String result, {bool truncated = false}) {
    _status = AiStatus.success;
    _result = result;
    _lastTruncated = truncated;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AiStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
