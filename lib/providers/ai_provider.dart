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

  AiStatus get status => _status;
  String get result => _result;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _aiService.isAvailable;
  AiBackend get activeBackend => _aiService.activeBackend;

  Future<void> initialize() async {
    await _aiService.initialize();
    notifyListeners();
  }

  void reset() {
    _status = AiStatus.idle;
    _result = '';
    _errorMessage = '';
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
        maxTokens: 256,
      );
      _setSuccess(result);
      return result;
    } on AiUnavailableException {
      _setError('Set up your API key in Settings to use AI features.');
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
      switch (action) {
        case WritingAction.expand:
          userPrompt = AiPrompts.writingExpand(selectedText);
        case WritingAction.rewrite:
          userPrompt = AiPrompts.writingRewrite(selectedText);
        case WritingAction.shorten:
          userPrompt = AiPrompts.writingShorten(selectedText);
        case WritingAction.continueWriting:
          userPrompt = AiPrompts.writingContinue(selectedText);
      }
      final result = await _aiService.generate(
        systemPrompt: AiPrompts.writingSystem,
        userPrompt: userPrompt,
        maxTokens: 512,
      );
      _setSuccess(result);
      return result;
    } on AiUnavailableException {
      _setError('Set up your API key in Settings to use AI features.');
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
      _setSuccess(result.trim());
      return result.trim();
    } on AiUnavailableException {
      _setError('Set up your API key in Settings to use AI features.');
      rethrow;
    } catch (e) {
      if (_status != AiStatus.error) _setError(e.toString());
      rethrow;
    }
  }

  // -- AI Search / Q&A --
  Future<String> askQuestion({
    required String question,
    required List<Note> notes,
  }) async {
    _setLoading();
    try {
      final buffer = StringBuffer();
      for (int i = 0; i < notes.length && buffer.length < 8000; i++) {
        final note = notes[i];
        final plainText = NotesProvider.getPlainText(note);
        buffer.writeln(
            '--- Note: ${note.title.isEmpty ? "Untitled" : note.title} ---');
        buffer.writeln(plainText.length > 500
            ? '${plainText.substring(0, 500)}...'
            : plainText);
        buffer.writeln();
      }
      final result = await _aiService.generate(
        systemPrompt: AiPrompts.qaSystem,
        userPrompt: AiPrompts.qaUser(question, buffer.toString()),
        maxTokens: 512,
      );
      _setSuccess(result);
      return result;
    } on AiUnavailableException {
      _setError('Set up your API key in Settings to use AI features.');
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

  void _setLoading() {
    _status = AiStatus.loading;
    _result = '';
    _errorMessage = '';
    notifyListeners();
  }

  void _setSuccess(String result) {
    _status = AiStatus.success;
    _result = result;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AiStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
