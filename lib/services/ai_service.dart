import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

enum AiBackend { claude, none }

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final SettingsService _settings = SettingsService();

  String? _apiKey;
  bool _initialized = false;

  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  AiBackend get activeBackend {
    if (_apiKey != null && _apiKey!.isNotEmpty) return AiBackend.claude;
    return AiBackend.none;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _refreshApiKey();
    _initialized = true;
  }

  Future<void> _refreshApiKey() async {
    _apiKey = await _settings.getApiKey();
  }

  Future<void> onApiKeyChanged() async {
    await _refreshApiKey();
  }

  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1024,
  }) async {
    if (!isAvailable) throw AiUnavailableException();
    return _generateClaude(systemPrompt, userPrompt, maxTokens);
  }

  Future<String> _generateClaude(
    String systemPrompt,
    String userPrompt,
    int maxTokens,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg = body['error']?['message'] ?? 'Unknown API error';
      throw AiApiException('Claude API error: $errorMsg');
    }

    final body = jsonDecode(response.body);
    final content = body['content'] as List;
    if (content.isEmpty) throw AiApiException('Empty response from Claude');

    final textBlock = content.firstWhere(
      (block) => block['type'] == 'text',
      orElse: () => throw AiApiException('No text in response'),
    );
    return textBlock['text'] as String;
  }

  void dispose() {
    // No persistent connections to clean up with http package
  }
}

class AiUnavailableException implements Exception {
  @override
  String toString() =>
      'No AI backend available. Please add your API key in Settings.';
}

class AiApiException implements Exception {
  final String message;
  AiApiException(this.message);

  @override
  String toString() => message;
}
