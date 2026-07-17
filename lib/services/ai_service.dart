import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

enum AiBackend { claude, none }

/// Result of an AI generation, carrying the text plus whether the model's
/// output was cut off by the token limit (so callers can warn before
/// destructively replacing user content with a truncated reply).
class AiResult {
  final String text;
  final bool truncated;

  const AiResult({required this.text, this.truncated = false});
}

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Selectable models. Aliases (no date suffix) so a model retirement is a
  /// config change, not a broken app. Kept in sync with SettingsService.
  static const Map<String, String> models = {
    'fast': 'claude-haiku-4-5-20251001',
    'balanced': 'claude-sonnet-5',
    'best': 'claude-opus-4-8',
  };
  static const String defaultModelKey = 'balanced';

  static const Duration _requestTimeout = Duration(seconds: 60);

  final SettingsService _settings = SettingsService();

  String? _apiKey;
  String _modelKey = defaultModelKey;
  bool _initialized = false;

  /// A shared client so in-flight requests can be aborted on demand.
  http.Client _client = http.Client();

  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  String get modelKey => _modelKey;
  String get modelId => models[_modelKey] ?? models[defaultModelKey]!;

  AiBackend get activeBackend {
    if (_apiKey != null && _apiKey!.isNotEmpty) return AiBackend.claude;
    return AiBackend.none;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _refreshApiKey();
    _modelKey = await _settings.getModelKey();
    _initialized = true;
  }

  Future<void> _refreshApiKey() async {
    _apiKey = await _settings.getApiKey();
  }

  Future<void> onApiKeyChanged() async {
    await _refreshApiKey();
  }

  Future<void> setModelKey(String key) async {
    if (!models.containsKey(key)) return;
    _modelKey = key;
    await _settings.setModelKey(key);
  }

  Future<AiResult> generate({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1024,
  }) async {
    if (!isAvailable) throw AiUnavailableException();
    return _generateClaude(systemPrompt, userPrompt, maxTokens);
  }

  Future<AiResult> _generateClaude(
    String systemPrompt,
    String userPrompt,
    int maxTokens,
  ) async {
    // Retry transient failures (429 rate-limit, 5xx, 529 overloaded) with
    // exponential backoff, honoring Retry-After when present.
    const maxAttempts = 3;
    AiApiException? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      http.Response response;
      try {
        response = await _client
            .post(
              Uri.parse('https://api.anthropic.com/v1/messages'),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey!,
                'anthropic-version': '2023-06-01',
              },
              body: jsonEncode({
                'model': modelId,
                'max_tokens': maxTokens,
                'system': systemPrompt,
                'messages': [
                  {'role': 'user', 'content': userPrompt},
                ],
              }),
            )
            .timeout(_requestTimeout);
      } on TimeoutException {
        throw AiApiException('Request timed out. Please try again.');
      } on SocketException {
        throw AiApiException(
            'No internet connection. Check your network and try again.');
      } on http.ClientException {
        throw AiApiException(
            'Connection interrupted. Please try again.');
      }

      if (response.statusCode == 200) {
        return _parseSuccess(response.body);
      }

      // Retryable status codes.
      if ((response.statusCode == 429 ||
              response.statusCode == 529 ||
              response.statusCode >= 500) &&
          attempt < maxAttempts - 1) {
        lastError = AiApiException(_friendlyStatusMessage(response));
        final wait = _retryAfter(response) ??
            Duration(milliseconds: 500 * (1 << attempt));
        await Future.delayed(wait);
        continue;
      }

      throw AiApiException(_errorMessage(response));
    }

    throw lastError ?? AiApiException('Noot AI is busy — try again in a moment.');
  }

  AiResult _parseSuccess(String responseBody) {
    dynamic body;
    try {
      body = jsonDecode(responseBody);
    } catch (_) {
      throw AiApiException('Received an unexpected response from Noot AI.');
    }

    if (body is! Map || body['content'] is! List) {
      throw AiApiException('Received an unexpected response from Noot AI.');
    }

    final content = body['content'] as List;
    final textBlock = content.firstWhere(
      (block) => block is Map && block['type'] == 'text',
      orElse: () => null,
    );
    final text = (textBlock is Map ? textBlock['text'] : null);
    if (text is! String || text.trim().isEmpty) {
      throw AiApiException('Noot AI returned an empty response.');
    }

    final truncated = body['stop_reason'] == 'max_tokens';
    return AiResult(text: text, truncated: truncated);
  }

  /// Build a user-facing message from a non-200 response, tolerating
  /// non-JSON bodies (e.g. captive-portal HTML).
  String _errorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'Invalid API key. Check your key in Settings.';
    }
    if (response.statusCode == 400) {
      return 'Noot AI couldn\'t process that. Your note may be too long.';
    }
    try {
      final body = jsonDecode(response.body);
      final error = body is Map ? body['error'] : null;
      final msg = error is Map ? error['message'] : null;
      if (msg is String && msg.isNotEmpty) return 'Noot AI: $msg';
    } catch (_) {
      // fall through to status-based message
    }
    return _friendlyStatusMessage(response);
  }

  String _friendlyStatusMessage(http.Response response) {
    switch (response.statusCode) {
      case 429:
      case 529:
        return 'Noot AI is busy — try again in a moment.';
      default:
        if (response.statusCode >= 500) {
          return 'Noot AI is temporarily unavailable. Try again shortly.';
        }
        return 'Something went wrong (HTTP ${response.statusCode}).';
    }
  }

  Duration? _retryAfter(http.Response response) {
    final header = response.headers['retry-after'];
    if (header == null) return null;
    final seconds = int.tryParse(header.trim());
    if (seconds == null || seconds < 0) return null;
    // Cap so a hostile header can't freeze the UI.
    return Duration(seconds: seconds.clamp(0, 10));
  }

  /// Abort any in-flight request (e.g. when the user dismisses a sheet) and
  /// prepare a fresh client for the next call.
  void cancelInFlight() {
    _client.close();
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }
}

class AiUnavailableException implements Exception {
  @override
  String toString() =>
      'Add your API key in Settings to use Noot AI features.';
}

class AiApiException implements Exception {
  final String message;
  AiApiException(this.message);

  @override
  String toString() => message;
}
