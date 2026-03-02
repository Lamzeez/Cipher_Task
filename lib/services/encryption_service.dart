import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'key_storage_service.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  Future<String> encryptNote(String plain) async {
    final keyBytes = await KeyStorageService.instance.getOrCreateAesKeyBytes();
    final key = enc.Key(Uint8List.fromList(keyBytes));

    // Random IV per message (recommended)
    final iv = enc.IV.fromSecureRandom(16);

    final aes = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = aes.encrypt(plain, iv: iv);

    // Store as: base64(iv) : base64(cipher)
    return '${base64Url.encode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> decryptNote(String cipher) async {
    if (cipher.trim().isEmpty) return '';
    final parts = cipher.split(':');
    if (parts.length != 2) return '';

    final ivBytes = base64Url.decode(parts[0]);
    final cipherB64 = parts[1];

    final keyBytes = await KeyStorageService.instance.getOrCreateAesKeyBytes();
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final iv = enc.IV(ivBytes);
    final aes = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
    return aes.decrypt64(cipherB64, iv: iv);
  }
}