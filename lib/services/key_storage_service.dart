import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class KeyStorageService {
  KeyStorageService._();
  static final KeyStorageService instance = KeyStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> setString(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> getString(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Generates a secure random key and stores it if not present.
  Future<List<int>> getOrCreateDbKeyBytes() async {
    final existing = await getString(AppConstants.kDbKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }

    // 32 bytes key for Hive encryption (AES-256 internally)
    final key = _randomBytes(32);
    await setString(AppConstants.kDbKey, base64Url.encode(key));
    return key;
    }

  /// AES-256 key (32 bytes) for field encryption of sensitive note
  Future<List<int>> getOrCreateAesKeyBytes() async {
    final existing = await getString(AppConstants.kAesKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }
    final key = _randomBytes(32);
    await setString(AppConstants.kAesKey, base64Url.encode(key));
    return key;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}