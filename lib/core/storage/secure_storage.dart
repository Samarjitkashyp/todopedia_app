import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Singleton pattern
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _usernameKey = "saved_username";

  // Write Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  // Read Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Write Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  // Read Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Write Username (for personalized greetings)
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  // Read Username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // Clear all credentials (Logout)
  Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
