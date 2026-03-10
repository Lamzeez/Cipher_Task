import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles picking, saving, and loading a local profile-picture file.
///
/// The image is stored at:
///   <appDocDir>/avatars/<sanitisedEmail>.jpg
///
/// Nothing is uploaded to the network.
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final _picker = ImagePicker();

  // ── public API ─────────────────────────────────────────────────────────────

  /// Returns the [File] for [email] if one has been saved, otherwise null.
  Future<File?> loadAvatar(String email) async {
    final path = await _avatarPath(email);
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Opens the system image-picker (gallery), saves a compressed copy, and
  /// returns the saved [File].  Returns null if the user cancels or an error
  /// occurs.
  Future<File?> pickAndSaveAvatar(String email) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,   // slight compression – keeps size small
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return null;

      final dest = File(await _avatarPath(email));
      await dest.parent.create(recursive: true);
      await File(picked.path).copy(dest.path);
      return dest;
    } catch (e) {
      debugPrint('AvatarService.pickAndSaveAvatar error: $e');
      return null;
    }
  }

  /// Deletes the saved avatar for [email], if it exists.
  Future<void> deleteAvatar(String email) async {
    try {
      final file = File(await _avatarPath(email));
      if (file.existsSync()) await file.delete();
    } catch (e) {
      debugPrint('AvatarService.deleteAvatar error: $e');
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<String> _avatarPath(String email) async {
    final dir = await getApplicationDocumentsDirectory();
    // Sanitise e-mail so it's safe as a filename.
    final safe = email.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return p.join(dir.path, 'avatars', '$safe.jpg');
  }
}