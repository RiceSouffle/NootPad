import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _apiKeyKey = 'anthropic_api_key';
  static const _preferLocalAiKey = 'prefer_local_ai';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: _apiKeyKey, value: key);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<bool> getPreferLocalAi() async {
    final value = await _secureStorage.read(key: _preferLocalAiKey);
    return value == 'true';
  }

  Future<void> setPreferLocalAi(bool prefer) async {
    await _secureStorage.write(key: _preferLocalAiKey, value: prefer.toString());
  }
}
